defmodule BlueJet.Storefront.Order do
  use BlueJet, :data

  use Trans, translates: [:custom_data], container: :translations

  import Money.Sigils

  alias BlueJet.Translation
  alias BlueJet.Storefront.Order
  alias BlueJet.Storefront.OrderLineItem
  alias BlueJet.Storefront.OrderCharge
  alias BlueJet.Identity.Account
  alias BlueJet.Identity.Customer
  alias BlueJet.Identity.User

  schema "orders" do
    field :code, :string
    field :status, :string, default: "cart"
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

    field :payment_status, :string, default: "pending" # pending, paid, partially_refunded, fully_refunded
    field :payment_gateway, :string # online, in_person,
    field :payment_processor, :string # stripe, paypal
    field :payment_method, :string # visa, mastercard ... , cash

    field :fulfillment_method, :string # ship, pickup

    field :placed_at, :utc_datetime
    field :confirmation_email_sent_at, :utc_datetime
    field :receipt_email_sent_at, :utc_datetime

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    timestamps()

    belongs_to :account, Account
    belongs_to :customer, Customer
    belongs_to :created_by, User
    has_many :line_items, OrderLineItem
    has_many :root_line_items, OrderLineItem
    has_many :charges, OrderCharge
  end

  def translatable_fields do
    Order.__trans__(:fields)
  end

  def system_fields do
    [
      :system_tag,
      :sub_total_cents,
      :tax_one_cents,
      :tax_two_cents,
      :tax_three_cents,
      :grant_total_cents,
      :pament_status,
      :placed_at,
      :confirmation_email_sent_at,
      :receipt_email_sent_at,
      :created_by_id
    ]
  end

  def billing_address_fields do
    [
      :billing_address_line_one,
      :billing_address_line_two,
      :billing_address_province,
      :billing_address_city,
      :billing_address_country_code,
      :billing_address_postal_code
    ]
  end

  def delivery_address_fields do
    [
      :delivery_address_line_one,
      :delivery_address_line_two,
      :delivery_address_province,
      :delivery_address_city,
      :delivery_address_country_code,
      :delivery_address_postal_code
    ]
  end

  def payment_fields do
    [
      :payment_gateway,
      :payment_processor,
      :payment_method
    ]
  end

  def writable_fields do
    Order.__schema__(:fields) -- system_fields()
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:account_id]
  end

  def required_fields do
    [
      :account_id,
      :status,
      :email,
      :first_name,
      :last_name
    ]
  end

  def required_fields(%{ status: "cart" }) do
    [:account_id, :status]
  end
  def required_fields(%{ status: "opened", fulfillment_method: fulfillment_method, payment_status: payment_status, payment_gateway: payment_gateway }) do
    rfields = required_fields()

    rfields =
      if fulfillment_method == "ship" do
        rfields ++ delivery_address_fields()
      else
        rfields
      end

    rfields =
      if payment_status != "pending" && payment_gateway == "online" do
        rfields ++ payment_fields()
      else
        rfields
      end

    rfields =
      if payment_status != "pending" && payment_gateway == "in_person" do
        rfields ++ (payment_fields() -- [:payment_processor])
      else
        rfields
      end

    rfields
  end
  def required_fields(changeset) do
    status = get_field(changeset, :status)
    fulfillment_method = get_field(changeset, :fulfillment_method)
    paymenet_status = get_field(changeset, :payment_status)
    payment_gateway = get_field(changeset, :payment_gateway)

    field_values = %{
      status: status,
      fulfillment_method: fulfillment_method,
      payment_status: paymenet_status,
      payment_gateway: payment_gateway
    }

    required_fields(field_values)
  end

  # TODO: if changeing from cart to opened status we need to check inventory
  def validate(changeset) do
    changeset
    |> validate_required(required_fields(changeset))
    |> validate_format(:email, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
    |> foreign_key_constraint(:account_id)
    |> validate_assoc_account_scope([:customer, :created_by])
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

  def changeset_for_balance(struct) do
    query = Ecto.assoc(struct, :root_line_items) |> OrderLineItem.root()

    sub_total_cents = Repo.aggregate(query, :sum, :sub_total_cents) || 0
    tax_one_cents = Repo.aggregate(query, :sum, :tax_one_cents) || 0
    tax_two_cents = Repo.aggregate(query, :sum, :tax_two_cents) || 0
    tax_three_cents = Repo.aggregate(query, :sum, :tax_three_cents) || 0
    grand_total_cents = Repo.aggregate(query, :sum, :grand_total_cents) || 0

    Ecto.Changeset.change(
      struct,
      sub_total_cents: sub_total_cents,
      tax_one_cents: tax_one_cents,
      tax_two_cents: tax_two_cents,
      tax_three_cents: tax_three_cents,
      grand_total_cents: grand_total_cents
    )
  end

  def balance!(struct) do
    changeset = changeset_for_balance(struct)
    Repo.update!(changeset)
  end

  def enforce_inventory!(_) do

  end

  def enforce_shipping_date_deadline!(_) do

  end

  def preload(struct_or_structs, targets) when length(targets) == 0 do
    struct_or_structs
  end
  def preload(struct_or_structs, targets) when is_list(targets) do
    [target | rest] = targets

    struct_or_structs
    |> Repo.preload(preload_keyword(target))
    |> Order.preload(rest)
  end

  def preload_keyword(:line_items) do
    [line_items: OrderLineItem.query()]
  end

  def preload_keyword(:root_line_items) do
    [root_line_items: OrderLineItem.query(:root)]
  end
  def preload_keyword({:root_line_items, line_item_preloads}) do
    [root_line_items: {OrderLineItem.query(:root), OrderLineItem.preload_keyword(line_item_preloads)}]
  end
end
