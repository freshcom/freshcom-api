defmodule BlueJet.Storefront.Order do
  use BlueJet, :data

  use Trans, translates: [:custom_data], container: :translations

  alias Ecto.Changeset
  alias BlueJet.AccessRequest
  alias BlueJet.Translation
  alias BlueJet.Billing
  alias BlueJet.CRM

  alias BlueJet.Storefront.Order
  alias BlueJet.Storefront.OrderLineItem

  @type t :: Ecto.Schema.t

  schema "orders" do
    field :account_id, Ecto.UUID
    field :code, :string
    field :status, :string, default: "cart"
    field :payment_status, :string, default: "pending"
    field :system_tag, :string
    field :label, :string

    field :email, :string
    field :first_name, :string
    field :last_name, :string
    field :other_name, :string
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
    field :fulfillment_status, :string, default: "pending"

    field :opened_at, :utc_datetime
    field :confirmation_email_sent_at, :utc_datetime
    field :receipt_email_sent_at, :utc_datetime

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    field :created_by_id, Ecto.UUID
    field :customer_id, Ecto.UUID
    field :customer, :map, virtual: true

    timestamps()

    has_many :line_items, OrderLineItem
    has_many :root_line_items, OrderLineItem
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

  def required_name_fields(_, _, other_name) do
    if other_name do
      []
    else
      [:first_name, :last_name]
    end
  end

  def required_fields(changeset) do
    id = get_field(changeset, :id)
    first_name = get_field(changeset, :first_name)
    last_name = get_field(changeset, :last_name)
    other_name = get_field(changeset, :other_name)

    required_name_fields = required_name_fields(first_name, last_name, other_name)

    fulfillment_method = get_field(changeset, :fulfillment_method)

    common_fields = [:account_id, :status, :fulfillment_status, :payment_status]
    common_fields_for_update = common_fields ++ [:email, :fulfillment_method] ++ required_name_fields
    cond do
      id && fulfillment_method == "ship" ->
        common_fields_for_update ++ (delivery_address_fields() -- [:delivery_address_line_two])
      id ->
        common_fields_for_update
      true -> common_fields
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
    |> validate_customer_id()
  end

  def validate_customer_id(changeset) do
    id = get_field(changeset, :id)
    customer_id = get_field(changeset, :customer_id)

    if customer_id do
      changeset
    else
      ordered_unlockable_count =
        from(oli in OrderLineItem, where: oli.order_id == ^id, where: oli.is_leaf == true, where: oli.source_type == "Unlockable")
        |> Repo.aggregate(:count, :id)

      # TODO: Also need to consider depositable
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
    |> put_opened_at()
    |> Translation.put_change(translatable_fields(), locale)
  end

  defp put_opened_at(changeset = %{ valid?: true, data: %{ status: "cart" }, changes: %{ status: "opened" } }) do
    Changeset.put_change(changeset, :opened_at, Ecto.DateTime.utc())
  end
  defp put_opened_at(changeset), do: changeset

  defp changeset_for_balance(struct) do
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
      sub_total_cents: sub_total_cents,
      tax_one_cents: tax_one_cents,
      tax_two_cents: tax_two_cents,
      tax_three_cents: tax_three_cents,
      grand_total_cents: grand_total_cents,
      authorization_cents: authorization_cents,
      is_estimate: is_estimate
    )
  end

  def balance(struct) do
    changeset = changeset_for_balance(struct)
    Repo.update!(changeset)
  end

  def refresh_payment_status(order) do
    order
    |> Changeset.change(payment_status: payment_status(order))
    |> Repo.update!()
  end
  defp payment_status(order) do
    payments = Billing.list_payment_for_target("Order", order.id)

    total_paid_amount_cents =
      payments
      |> Enum.filter(fn(payment) -> payment.status == "paid" || payment.status == "partially_refunded" || payment.status == "refunded" end)
      |> Enum.reduce(0, fn(payment, acc) -> acc + payment.amount_cents end)

    total_gross_amount_cents =
      payments
      |> Enum.filter(fn(payment) -> payment.status == "paid" || payment.status == "partially_refunded" || payment.status == "refunded" end)
      |> Enum.reduce(0, fn(payment, acc) -> acc + payment.gross_amount_cents end)

    total_authorized_amount_cents =
      payments
      |> Enum.filter(fn(payment) -> payment.status == "authorized" end)
      |> Enum.reduce(0, fn(payment, acc) -> acc + payment.amount_cents end)

    cond do
      order.grand_total_cents == 0 -> "paid"
      total_paid_amount_cents >= order.grand_total_cents && total_gross_amount_cents <= 0 -> "refunded"
      total_paid_amount_cents >= order.grand_total_cents && total_gross_amount_cents < order.grand_total_cents -> "partially_refunded"
      total_paid_amount_cents >= order.grand_total_cents && total_gross_amount_cents == order.grand_total_cents -> "paid"
      total_paid_amount_cents >= order.grand_total_cents && total_gross_amount_cents > order.grand_total_cents -> "over_paid"
      total_paid_amount_cents > 0 -> "partially_paid"
      total_authorized_amount_cents >= order.authorization_cents -> "authorized"
      total_authorized_amount_cents > 0 -> "partially_authorized"
      true -> "pending"
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

  def customer(%{ customer_id: nil }), do: nil
  def customer(order = %{ customer: nil }) do
    {:ok, %{ data: customer }} = CRM.do_get_customer(%AccessRequest{
      vas: %{ account_id: order.account_id },
      params: %{ "id" => order.customer_id }
    })

    customer
  end
  def customer(%{ customer: customer }), do: customer

  def put_external_resources(order, :customer) do
    %{ order | customer: customer(order) }
  end

  #####
  # Business Functions
  #####

  @doc """
  Process the given `order` so that other related resource can be created/updated.

  This function may change the order in database.
  """
  def process(order), do: {:ok, order}
  def process(order, changeset = %Changeset{ data: %{ status: "cart" }, changes: %{ status: "opened" } }) do
    order = put_external_resources(order, :customer)

    leaf_line_items = Order.leaf_line_items(order)
    Enum.each(leaf_line_items, fn(line_item) ->
      OrderLineItem.process(line_item, order, changeset, order.customer)
    end)

    {:ok, order}
  end
  def process(order, _), do: {:ok, order}

  defmodule Query do
    use BlueJet, :query

    def for_account(query, account_id) do
      from(o in query, where: o.account_id == ^account_id)
    end

    def preloads(:root_line_items) do
      [root_line_items: OrderLineItem.Query.root()]
    end
    def preloads({:root_line_items, root_line_item_preloads}) do
      [root_line_items: {OrderLineItem.Query.root(), OrderLineItem.Query.preloads(root_line_item_preloads)}]
    end
    def preloads(_) do
      []
    end

    def not_cart(query) do
      from(o in query, where: o.status != "cart")
    end

    def default() do
      from(o in Order, order_by: [desc: o.opened_at, desc: o.inserted_at])
    end
  end
end
