defmodule BlueJet.Billing.Refund do
  use BlueJet, :data

  use Trans, translates: [:custom_data], container: :translations

  alias Ecto.Changeset
  alias BlueJet.Translation

  alias BlueJet.Billing.Refund
  alias BlueJet.Billing.Payment

  @type t :: Ecto.Schema.t

  schema "refunds" do
    field :account_id, Ecto.UUID
    field :status, :string
    field :amount_cents, :integer
    field :stripe_refund_id, :string

    field :owner_id, Ecto.UUID
    field :owner_type, :string

    field :target_id, Ecto.UUID
    field :target_type, :string

    field :notes, :string

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    timestamps()

    belongs_to :payment, Payment
  end

  def system_fields do
    [
      :id,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    Refund.__schema__(:fields) -- system_fields()
  end

  def translatable_fields do
    Refund.__trans__(:fields)
  end

  def castable_fields(%Refund{ __meta__: %{ state: :built }}) do
    writable_fields()
  end
  def castable_fields(payment = %Refund{ __meta__: %{ state: :loaded }}) do
    writable_fields -- [:amount_cents]
  end

  def validate(changeset) do
    changeset
    |> validate_required([:amount_cents, :payment_id])
    |> foreign_key_constraint(:account_id)
    |> validate_assoc_account_scope(:payment)
    |> validate_amount_cents()
  end

  defp validate_amount_cents(changeset) do
    amount_cents = get_field(changeset, :amount_cents)
    account_id = get_field(changeset, :account_id)
    payment_id = get_field(changeset, :payment_id)
    payment = Repo.get_by!(Payment, account_id: account_id, id: payment_id)

    case amount_cents > payment.gross_amount_cents do
      true -> Changeset.add_error(changeset, :amount_cents, "Amount Cents cannot be greater than the Payment's Gross Amount Cents", [validation: "amount_cents_must_be_smaller_or_equal_to_payment_gross_amount_cents", full_error_message: true])
      _ -> changeset
    end
  end
  defp validate_paid_amount_cents(changeset), do: changeset

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}, locale \\ "en") do
    struct
    |> cast(params, castable_fields(struct))
    |> validate()
    |> Translation.put_change(translatable_fields(), locale)
  end

  def query() do
    from(r in Refund, order_by: [desc: r.updated_at, desc: r.inserted_at])
  end

  @spec process(Refund.t, Changeset.t) :: {:ok, Refund.t} | {:error. map}
  def process(refund, %{ data: %{ amount_cents: nil }, changes: %{ amount_cents: amount_cents } }) do
    with {:ok, stripe_refund} = create_stripe_refund(refund) do
      sync_with_stripe_refund(refund, stripe_refund)
    else
      {:error, stripe_errors} -> {:error, format_stripe_errors(stripe_errors)}
    end
  end
  def process(refund, _), do: {:ok, refund}

  @spec sync_with_stripe_refund(Refund.t, map) :: {:ok, Refund.t}
  defp sync_with_stripe_refund(refund, %{ "id" => stripe_refund_id, "status" => status }) do
    refund
      refund
      |> Changeset.change(stripe_refund_id: stripe_refund_id, status: status)
      |> Repo.update!()

    {:ok, refund}
  end

  def create_stripe_refund(refund) do
    refund = refund |> Repo.preload(:payment)
    stripe_charge_id = refund.payment.stripe_charge_id
    StripeClient.post("/refunds", %{ charge: stripe_charge_id, amount: refund.amount_cents, metadata: %{ fc_refund_id: refund.id }  })
  end

  defp format_stripe_errors(stripe_errors = %{}) do
    [source: { stripe_errors["error"]["message"], [code: stripe_errors["error"]["code"], full_error_message: true] }]
  end
  defp format_stripe_errors(stripe_errors), do: stripe_errors

  defmodule Query do
    use BlueJet, :query

    def for_account(query, account_id) do
      from(r in query, where: r.account_id == ^account_id)
    end

    def default() do
      from(r in Refund, order_by: [desc: :updated_at])
    end
  end
end
