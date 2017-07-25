defmodule BlueJet.Order do
  use BlueJet.Web, :model

  schema "order" do
    field :code, :string
    field :status, :string
    field :system_tag, :string
    field :label, :string

    field :email, :string
    field :first_name, :string
    field :last_name, :string
    field :phone_number, :string

    field :delivery_address_line_one, :string
    field :delivery_address_line_two, :string
    field :delivery_address_province, :string
    field :delivery_address_city, :string
    field :delivery_address_country_code, :string
    field :delivery_address_postal_code, :string

    field :billing_address_line_one, :string
    field :billing_address_line_two, :string
    field :billing_address_province, :string
    field :billing_address_city, :string
    field :billing_address_country_code, :string
    field :billing_address_postal_code, :string

    field :sub_total_cents, :integer, default: 0
    field :tax_one_cents, :integer, default: 0
    field :tax_two_cents, :integer, default: 0
    field :tax_three_cents, :integer, default: 0
    field :grand_total_cents, :integer, default: 0

    field :payment_status, :string
    field :payment_processor, :string
    field :payment_method, :string

    field :fulfillment_method, :string

    field :placed_at, :utc_datetime
    field :confirmation_email_sent_at, :utc_datetime
    field :receipt_email_sent_at, :utc_datetime

    field :custom_data, :map, default: %{}

    timestamps()

    belongs_to :account, BlueJet.Account
    belongs_to :customer, BlueJet.Customer
    belongs_to :created_by, BlueJet.User
  end

  def translatable_fields do
    []
  end

  def castable_fields(state) do
    all = BlueJet.Order.__schema__(:fields) -- [:id, :inserted_at, :updated_at, :placed_at]

    case state do
      :built -> all
      :loaded -> all -- [:account_id, :customer_id, :created_by_id]
    end
  end

  def required_fields do
    [:account_id]
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct = %{ __meta__: %{ state: state } }, params \\ %{}) do
    struct
    |> cast(params, castable_fields(state))
    |> validate_required(required_fields())
  end
end
