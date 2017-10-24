defmodule BlueJet.Storefront.Refund do
  use BlueJet, :data

  use Trans, translates: [:custom_data], container: :translations

  alias Ecto.Changeset
  alias BlueJet.Translation
  alias BlueJet.Storefront.Payment
  alias BlueJet.Identity.Account
  alias BlueJet.Storefront.Refund

  schema "refunds" do
    field :amount_cents, :integer
    field :stripe_refund_id, :string

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    timestamps()

    belongs_to :account, Account
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

    case amount_cents > payment.paid_amount_cents - payment.refunded_amount_cents do
      true -> Changeset.add_error(changeset, :amount_cents, "Amount Cents cannot be greater than the Payment's net Paid Amount Cents", [validation: "amount_cents_must_be_smaller_or_equal_to_payment_net_paid_amount_cents", full_error_message: true])
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

end
