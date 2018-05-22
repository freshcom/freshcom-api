defmodule BlueJet.Balance.Refund do
  use BlueJet, :data

  alias BlueJet.Balance.Payment
  alias __MODULE__.Proxy

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

  @type t :: Ecto.Schema.t()

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
    [:caption, :description, :custom_data]
  end

  @spec changeset(__MODULE__.t(), atom, map) :: Changeset.t()
  def changeset(refund, :insert, params) do
    refund
    |> cast(params, castable_fields(:insert))
    |> Map.put(:action, :insert)
    |> validate()
  end

  def changeset(refund, :update, params, locale \\ nil, default_locale \\ nil) do
    refund = Proxy.put_account(refund)
    default_locale = default_locale || refund.account.default_locale
    locale = locale || default_locale

    refund
    |> cast(params, castable_fields(:update))
    |> Map.put(:action, :update)
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  defp castable_fields(:insert) do
    writable_fields()
  end

  defp castable_fields(:update) do
    writable_fields() -- [:amount_cents]
  end

  @spec validate(Changeset.t()) :: Changeset.t()
  def validate(changeset) do
    changeset
    |> validate_required(required_fields(changeset))
    |> validate_number(:amount_cents, greater_than: 0)
    |> validate_amount_cents()
    |> validate_payment_id()
  end

  defp required_fields(changeset) do
    gateway = get_field(changeset, :gateway)
    common = [:amount_cents, :payment_id, :gateway]

    case gateway do
      "freshcom" -> common ++ [:processor]
      "offline" -> common ++ [:method]
      _ -> common
    end
  end

  defp validate_amount_cents(changeset = %{valid?: true}) do
    amount_cents = get_field(changeset, :amount_cents)
    account_id = get_field(changeset, :account_id)
    payment_id = get_field(changeset, :payment_id)
    payment = Repo.get_by!(Payment, account_id: account_id, id: payment_id)

    case amount_cents > payment.gross_amount_cents do
      true ->
        add_error(
          changeset,
          :amount_cents,
          "Amount cannot be greater than the payment's gross amount",
          code: "cannot_be_gt_payment_gross_amount"
        )

      _ ->
        changeset
    end
  end

  defp validate_amount_cents(changeset), do: changeset

  # TODO
  defp validate_payment_id(changeset) do
    changeset
  end

  @spec process(__MODULE__.t(), Changeset.t()) :: {:ok, __MODULE__.t()} | {:error.map()}
  def process(%{gateway: "freshcom"} = refund, %{
        data: %{amount_cents: nil},
        changes: %{amount_cents: _}
      }) do
    refund = Proxy.put_account(refund)

    with {:ok, stripe_refund} <- Proxy.create_stripe_refund(refund),
         {:ok, stripe_transfer_reversal} <-
           Proxy.create_stripe_transfer_reversal(refund, stripe_refund) do
      refund =
        sync_from_stripe_refund_and_transfer_reversal(
          refund,
          stripe_refund,
          stripe_transfer_reversal
        )

      Payment
      |> Repo.get(refund.payment_id)
      |> Payment.sync_from_refund(refund)

      {:ok, refund}
    else
      {:error, stripe_errors} ->
        {:error, format_stripe_errors(stripe_errors)}

      other ->
        other
    end
  end

  def process(refund, %{action: :insert}) do
    Payment
    |> Repo.get(refund.payment_id)
    |> Payment.sync_from_refund(refund)

    {:ok, refund}
  end

  def process(refund, _), do: {:ok, refund}

  defp sync_from_stripe_refund_and_transfer_reversal(
         refund,
         stripe_refund,
         stripe_transfer_reversal
       ) do
    processor_fee_cents = -stripe_refund["balance_transaction"]["fee"]

    freshcom_fee_cents =
      refund.amount_cents - stripe_transfer_reversal["amount"] - processor_fee_cents

    refund
    |> change(
      stripe_refund_id: stripe_refund["id"],
      stripe_transfer_reversal_id: stripe_transfer_reversal["id"],
      processor_fee_cents: processor_fee_cents,
      freshcom_fee_cents: freshcom_fee_cents,
      status: stripe_refund["status"]
    )
    |> Repo.update!()
  end

  defp format_stripe_errors(stripe_errors = %{}) do
    [
      source:
        {stripe_errors["error"]["message"],
         [code: stripe_errors["error"]["code"], full_error_message: true]}
    ]
  end

  defp format_stripe_errors(stripe_errors), do: stripe_errors
end
