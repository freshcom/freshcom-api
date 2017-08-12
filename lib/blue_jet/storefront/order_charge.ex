defmodule BlueJet.Storefront.OrderCharge do
  use BlueJet, :data

  use Trans, translates: [:custom_data], container: :translations

  alias BlueJet.Translation
  alias BlueJet.Storefront.OrderCharge
  alias BlueJet.Storefront.Order
  alias BlueJet.Identity.Account

  schema "order_charges" do
    field :status, :string
    field :authorized_amount_cents, :integer
    field :captured_amount_cents, :integer
    field :refunded_amount_cents, :integer

    field :stripe_charge_id, :string

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    timestamps()

    belongs_to :account, Account
    belongs_to :order, Order
  end

  def system_fields do
    [
      :id,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    OrderCharge.__schema__(:fields) -- system_fields()
  end

  def translatable_fields do
    OrderCharge.__trans__(:fields)
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:account_id, :order_id]
  end

  def required_fields do
    [:account_id, :order_id]
  end

  def validate(changeset) do
    changeset
    |> validate_required(required_fields())
    |> validate_assoc_account_scope(:order)
  end

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
