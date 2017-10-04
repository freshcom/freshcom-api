defmodule BlueJet.Storefront.Payment do
  use BlueJet, :data

  use Trans, translates: [:custom_data], container: :translations

  alias BlueJet.Translation
  alias BlueJet.Storefront.Payment
  alias BlueJet.Storefront.Order
  alias BlueJet.Identity.Account

  schema "order_charges" do
    field :status, :string # pending, paid, partially_refunded, fully_refunded

    field :gateway, :string # online, in_person,
    field :processor, :string # stripe, paypal
    field :method, :string # visa, mastercard ... , cash

    field :authorized_amount_cents, :integer
    field :captured_amount_cents, :integer
    field :refunded_amount_cents, :integer

    field :billing_address_line_one, :string
    field :billing_address_line_two, :string
    field :billing_address_province, :string
    field :billing_address_city, :string
    field :billing_address_country_code, :string
    field :billing_address_postal_code, :string

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
    Payment.__schema__(:fields) -- system_fields()
  end

  def translatable_fields do
    Payment.__trans__(:fields)
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
