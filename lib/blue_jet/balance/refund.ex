defmodule BlueJet.Balance.Refund do
  use BlueJet, :data

  use Trans, translates: [
    :caption,
    :description,
    :custom_data
  ], container: :translations

  alias Decimal, as: D
  alias Ecto.Changeset

  alias BlueJet.Balance.Payment
  alias BlueJet.Balance.{StripeClient, IdentityService}

  schema "refunds" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :status, :string
    field :code, :string
    field :label, :string

    field :gateway, :string
    field :processor, :string
    field :method, :string

    field :amount_cents, :integer
    field :processor_fee_cents, :integer, default: 0
    field :freshcom_fee_cents, :integer, default: 0

    field :stripe_refund_id, :string
    field :stripe_transfer_reversal_id, :string

    field :caption, :string
    field :description, :string
    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    field :owner_id, Ecto.UUID
    field :owner_type, :string
    field :owner, :map, virtual: true

    field :target_id, Ecto.UUID
    field :target_type, :string
    field :target, :map, virtual: true

    timestamps()

    belongs_to :payment, Payment
  end

  @type t :: Ecto.Schema.t

  @system_fields [
    :id,
    :account_id,
    :processor_fee_cents,
    :freshcom_fee_cents,
    :stripe_refund_id,
    :stripe_transfer_reversal_id,
    :inserted_at,
    :updated_at
  ]

  def writable_fields do
    __MODULE__.__schema__(:fields) -- @system_fields
  end

  def translatable_fields do
    __MODULE__.__trans__(:fields)
  end

  def castable_fields(%__MODULE__{ __meta__: %{ state: :built }}) do
    writable_fields()
  end

  def castable_fields(%__MODULE__{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:amount_cents]
  end

  def required_fields(changeset) do
    gateway = get_field(changeset, :gateway)
    common = [:amount_cents, :payment_id, :gateway]

    case gateway do
      "online" -> common ++ [:processor]
      "offline" -> common ++ [:method]
      _ -> common
    end
  end

  defp validate_amount_cents(changeset = %{ valid?: true }) do
    amount_cents = get_field(changeset, :amount_cents)
    account_id = get_field(changeset, :account_id)
    payment_id = get_field(changeset, :payment_id)
    payment = Repo.get_by!(Payment, account_id: account_id, id: payment_id)

    case amount_cents > payment.gross_amount_cents do
      true -> add_error(changeset, :amount_cents, "Amount cannot be greater than the payment's gross amount", [validation: "lte_payment_gross_amount", full_error_message: true])
      _ -> changeset
    end
  end

  defp validate_amount_cents(changeset), do: changeset

  # TODO:
  defp validate_payment_id(changeset) do
    changeset
  end

  def validate(changeset) do
    changeset
    |> validate_required(required_fields(changeset))
    |> validate_number(:amount_cents, greater_than: 0)
    |> validate_amount_cents()
    |> validate_payment_id()
  end

  def changeset(refund, params, locale \\ nil, default_locale \\ nil) do
    refund = %{ refund | account: get_account(refund) }
    default_locale = default_locale || refund.account.default_locale
    locale = locale || default_locale

    refund
    |> cast(params, castable_fields(refund))
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  #
  # MARK: External Resources
  #
  def get_account(refund) do
    refund.account || IdentityService.get_account(refund)
  end

  use BlueJet.FileStorage.Macro,
    put_external_resources: :file_collection,
    field: :file_collections,
    owner_type: "Refund"

  def put_external_resources(refund, _, _), do: refund

  @spec process(__MODULE__.t, Changeset.t) :: {:ok, __MODULE__.t} | {:error. map}
  def process(refund = %{ gateway: "online" }, %{ data: %{ amount_cents: nil }, changes: %{ amount_cents: _ } }) do
    refund = %{ refund | account: get_account(refund) }
    with {:ok, stripe_refund} <- create_stripe_refund(refund),
         {:ok, stripe_transfer_reversal} <- create_stripe_transfer_reversal(refund, stripe_refund)
    do
      sync_with_stripe_refund_and_transfer_reversal(refund, stripe_refund, stripe_transfer_reversal)
    else
      {:error, stripe_errors} -> {:error, format_stripe_errors(stripe_errors)}
    end
  end
  def process(refund, _), do: {:ok, refund}

  @spec sync_with_stripe_refund_and_transfer_reversal(__MODULE__.t, map, map) :: {:ok, __MODULE__.t}
  defp sync_with_stripe_refund_and_transfer_reversal(refund, stripe_refund, stripe_transfer_reversal) do
    processor_fee_cents = -stripe_refund["balance_transaction"]["fee"]
    freshcom_fee_cents = refund.amount_cents - stripe_transfer_reversal["amount"] - processor_fee_cents

    refund =
      refund
      |> change(
          stripe_refund_id: stripe_refund["id"],
          stripe_transfer_reversal_id: stripe_transfer_reversal["id"],
          processor_fee_cents: processor_fee_cents,
          freshcom_fee_cents: freshcom_fee_cents,
          status: stripe_refund["status"]
         )
      |> Repo.update!()

    {:ok, refund}
  end

  def create_stripe_refund(refund) do
    refund = refund |> Repo.preload(:payment)
    stripe_charge_id = refund.payment.stripe_charge_id

    account = get_account(refund)
    StripeClient.post("/refunds", %{
      charge: stripe_charge_id,
      amount: refund.amount_cents,
      metadata: %{ fc_refund_id: refund.id },
      expand: ["balance_transaction", "charge.balance_transaction"]
    }, mode: account.mode)
  end

  def create_stripe_transfer_reversal(refund, stripe_refund) do
    refund = refund |> Repo.preload(:payment)

    stripe_fee_cents = -stripe_refund["balance_transaction"]["fee"]
    freshcom_fee_rate = D.new(refund.payment.freshcom_fee_cents) |> D.div(D.new(refund.payment.amount_cents))
    freshcom_fee_cents = freshcom_fee_rate |> D.mult(D.new(refund.amount_cents)) |> D.round() |> D.to_integer()

    transfer_reversal_amount_cents = refund.amount_cents - stripe_fee_cents - freshcom_fee_cents

    account = get_account(refund)
    StripeClient.post("/transfers/#{refund.payment.stripe_transfer_id}/reversals", %{
      amount: transfer_reversal_amount_cents,
      metadata: %{ fc_refund_id: refund.id }
    }, mode: account.mode)
  end

  defp format_stripe_errors(stripe_errors = %{}) do
    [source: { stripe_errors["error"]["message"], [code: stripe_errors["error"]["code"], full_error_message: true] }]
  end
  defp format_stripe_errors(stripe_errors), do: stripe_errors

  defmodule Query do
    use BlueJet, :query

    alias BlueJet.Balance.Refund

    def for_account(query, account_id) do
      from(r in query, where: r.account_id == ^account_id)
    end

    def default() do
      from(r in Refund, order_by: [desc: :updated_at])
    end
  end
end
