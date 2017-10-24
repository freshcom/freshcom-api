defmodule BlueJet.Storefront.Order do
  use BlueJet, :data

  use Trans, translates: [:custom_data], container: :translations

  alias Ecto.Changeset
  alias BlueJet.Translation
  alias BlueJet.Storefront.Order
  alias BlueJet.Storefront.OrderLineItem
  alias BlueJet.Storefront.Payment
  alias BlueJet.Identity.Account
  alias BlueJet.Identity.Customer
  alias BlueJet.Identity.User

  schema "orders" do
    field :code, :string
    field :status, :string, default: "cart"
    field :system_tag, :string
    field :label, :string
    field :is_payment_balanced, :boolean, default: false

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

    field :sub_total_cents, :integer, default: 0
    field :tax_one_cents, :integer, default: 0
    field :tax_two_cents, :integer, default: 0
    field :tax_three_cents, :integer, default: 0
    field :grand_total_cents, :integer, default: 0
    field :authorization_cents, :integer, default: 0

    field :is_estimate, :boolean, default: false

    field :fulfillment_method, :string # ship, pickup

    field :opened_at, :utc_datetime
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
    has_many :payments, Payment
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

  def writable_fields do
    Order.__schema__(:fields) -- system_fields()
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields() -- [:status]
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

  def required_fields(changeset) do
    fulfillment_method = get_field(changeset, :fulfillment_method)

    if fulfillment_method == "ship" do
      required_fields() ++ (delivery_address_fields() -- [:delivery_address_line_two])
    else
      required_fields()
    end
  end

  # TODO: if changeing from cart to opened status we need to check inventory
  def validate(changeset, %{ __meta__: %{ state: :built } }) do
    changeset
  end
  def validate(changeset, _) do
    changeset
    |> validate_required(required_fields(changeset))
    |> validate_format(:email, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
    |> foreign_key_constraint(:account_id)
    |> validate_assoc_account_scope([:customer, :created_by])
    |> validate_customer_id()
  end

  def validate_customer_id(changeset) do
    id = get_field(changeset, :id)
    customer_id = get_field(changeset, :customer_id)

    if customer_id do
      changeset
    else
      ordered_unlockable_count =
        from(oli in OrderLineItem, where: oli.order_id == ^id, where: oli.is_leaf == true, where: not is_nil(oli.unlockable_id))
        |> Repo.aggregate(:count, :id)

      case ordered_unlockable_count do
        0 -> changeset
        _ -> Changeset.add_error(changeset, :customer, "An Order that contains Unlockable must be associated to a Customer.", [validation: "order_with_unlockable_must_associate_customer", full_error_message: true])
      end
    end
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}, locale \\ "en") do
    struct
    |> cast(params, castable_fields(struct))
    |> validate(struct)
    |> Translation.put_change(translatable_fields(), locale)
  end

  def changeset_for_balance(struct) do
    query = Ecto.assoc(struct, :root_line_items) |> OrderLineItem.root()

    sub_total_cents = Repo.aggregate(query, :sum, :sub_total_cents) || 0
    tax_one_cents = Repo.aggregate(query, :sum, :tax_one_cents) || 0
    tax_two_cents = Repo.aggregate(query, :sum, :tax_two_cents) || 0
    tax_three_cents = Repo.aggregate(query, :sum, :tax_three_cents) || 0
    grand_total_cents = Repo.aggregate(query, :sum, :grand_total_cents) || 0
    authorization_cents = Repo.aggregate(query, :sum, :authorization_cents) || 0

    root_line_items = Repo.all(query)
    estimate_count = Enum.reduce(root_line_items, 0, fn(item, acc) ->
      if item.is_estimate do
        acc + 1
      else
        acc
      end
    end)

    is_estimate = if estimate_count > 0 do
      true
    else
      false
    end

    Changeset.change(
      struct,
      is_payment_balanced: is_payment_balanced(%{ struct | authorization_cents: authorization_cents, grand_total_cents: grand_total_cents }),
      sub_total_cents: sub_total_cents,
      tax_one_cents: tax_one_cents,
      tax_two_cents: tax_two_cents,
      tax_three_cents: tax_three_cents,
      grand_total_cents: grand_total_cents,
      authorization_cents: authorization_cents,
      is_estimate: is_estimate
    )
  end

  def balance!(struct) do
    changeset = changeset_for_balance(struct)
    Repo.update!(changeset)
  end

  def is_payment_balanced(struct = %Order{ status: "cart" }), do: false
  def is_payment_balanced(struct) do
    payments = Repo.all(Ecto.assoc(struct, :payments))
    payment_amount_cents = Enum.reduce(payments, 0, fn(payment, acc) ->
      case payment.status do
        "pending" -> acc + payment.pending_amount_cents
        "authorized" -> acc + payment.authorized_amount_cents
        "paid" -> acc + payment.paid_amount_cents
        "partially_refunded" -> acc + payment.paid_amount_cents - payment.refunded_amount_cents
        "refunded" -> acc
        _ -> acc
      end
    end)

    cond do
      struct.is_estimate && (payment_amount_cents >= struct.authorization_cents) -> true
      !struct.is_estimate && payment_amount_cents == struct.grand_total_cents -> true
      true -> false
    end
  end


  def leaf_line_items(struct) do
    Ecto.assoc(struct, :line_items) |> OrderLineItem.leaf() |> Repo.all()
  end

  def lock_stock(_) do
    {:ok, nil}
  end

  def lock_shipping_date(_) do
    {:ok, nil}
  end

  def query() do
    from(o in Order, order_by: [desc: o.opened_at, desc: o.inserted_at])
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
  def preload_keyword(:payments) do
    [payments: Payment.query()]
  end
  def preload_keyword(:root_line_items) do
    [root_line_items: OrderLineItem.query(:root)]
  end
  def preload_keyword({:root_line_items, line_item_preloads}) do
    [root_line_items: {OrderLineItem.query(:root), OrderLineItem.preload_keyword(line_item_preloads)}]
  end
end
