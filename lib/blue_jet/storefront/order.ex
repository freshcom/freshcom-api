defmodule BlueJet.Storefront.Order do
  @moduledoc """

  ## Status
  - cart
  - opened
  - closed
  - cancelled

  ## Fulfillment
  - pending
  - fulfilled
  - returned
  - discarded

  ## Payment
  - pending
  - authorized
  - partially_authorized
  - partially_paid
  - paid
  - over_paid
  - partially_refunded
  - refunded


  """
  use BlueJet, :data

  use Trans, translates: [
    :caption,
    :description,
    :custom_data
  ], container: :translations

  alias BlueJet.Storefront.{BalanceService, DistributionService, IdentityService, CrmService}
  alias BlueJet.Storefront.{Order, OrderLineItem}

  schema "orders" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :status, :string, default: "cart"
    field :code, :string
    field :name, :string
    field :label, :string

    field :payment_status, :string, default: "pending"
    field :fulfillment_status, :string, default: "pending"
    field :fulfillment_method, :string
    field :system_tag, :string

    field :email, :string
    field :first_name, :string
    field :last_name, :string
    field :phone_number, :string

    field :sub_total_cents, :integer, default: 0
    field :tax_one_cents, :integer, default: 0
    field :tax_two_cents, :integer, default: 0
    field :tax_three_cents, :integer, default: 0
    field :grand_total_cents, :integer, default: 0
    field :authorization_total_cents, :integer, default: 0
    field :is_estimate, :boolean, default: false

    field :delivery_address_line_one, :string
    field :delivery_address_line_two, :string
    field :delivery_address_province, :string
    field :delivery_address_city, :string
    field :delivery_address_country_code, :string
    field :delivery_address_postal_code, :string

    field :opened_at, :utc_datetime
    field :confirmation_email_sent_at, :utc_datetime
    field :receipt_email_sent_at, :utc_datetime

    field :caption, :string
    field :description, :string
    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    field :customer_id, Ecto.UUID
    field :customer, :map, virtual: true

    field :user_id, Ecto.UUID

    timestamps()

    has_many :line_items, OrderLineItem
    has_many :root_line_items, OrderLineItem
  end

  @type t :: Ecto.Schema.t

  @system_fields [
    :account_id,
    :system_tag,
    :payment_status,
    :fulfillment_status,
    :sub_total_cents,
    :tax_one_cents,
    :tax_two_cents,
    :tax_three_cents,
    :grant_total_cents,
    :authorization_total_cents,
    :placed_at,
    :confirmation_email_sent_at,
    :receipt_email_sent_at,
    :created_by_id
  ]

  @email_regex ~r/^[A-Za-z0-9._%+-+']+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/

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

  @doc """
  Returns a list of fields that is changable by user input.
  """
  def writable_fields do
    __MODULE__.__schema__(:fields) -- @system_fields
  end

  @doc """
  Returns a list of fields that can be translated.
  """
  def translatable_fields do
    __MODULE__.__trans__(:fields)
  end

  defp required_fields(%{ data: %{ __meta__: %{ state: :built } } }), do: required_fields()

  defp required_fields(changeset) do
    fulfillment_method = get_field(changeset, :fulfillment_method)

    case fulfillment_method do
      "ship" -> required_fields() ++ (delivery_address_fields() -- [:delivery_address_line_two])

      _ -> required_fields()
    end
  end

  defp required_fields, do: [:name, :status, :email, :fulfillment_method]

  # TODO:
  defp validate_inventory(changeset) do
    changeset
  end

  defp validate_customer_id(changeset) do
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

        _ -> add_error(changeset, :customer, "An Order that contains Unlockable must be associated to a Customer.", [validation: :required_for_unlockable, full_error_message: true])
      end
    end
  end

  @doc """
  Returns the validated changeset.
  """
  def validate(changeset = %{ data: %{ __meta__: %{ state: :built } } }) do
    changeset
  end

  def validate(changeset) do
    required_fields = required_fields(changeset)

    changeset
    |> validate_required(required_fields)
    |> validate_format(:email, @email_regex)
    |> validate_inventory()
    |> validate_customer_id()
  end

  defp castable_fields(%{ __meta__: %{ state: :built }}), do: writable_fields() -- [:status]
  defp castable_fields(%{ __meta__: %{ state: :loaded }}), do: writable_fields()

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(order, params, locale \\ nil, default_locale \\ nil) do
    order = %{ order | account: IdentityService.get_account(order) }
    default_locale = default_locale || order.account.default_locale
    locale = locale || default_locale

    order
    |> cast(params, castable_fields(order))
    |> put_name()
    |> validate()
    |> put_opened_at()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  defp put_name(changeset = %{ changes: %{ name: _ } }), do: changeset

  defp put_name(changeset) do
    first_name = get_field(changeset, :first_name)
    last_name = get_field(changeset, :last_name)

    cond do
      first_name && last_name ->
        put_change(changeset, :name, "#{first_name} #{last_name}")

      true ->
        put_change(changeset, :name, nil)
    end
  end

  defp put_opened_at(changeset = %{ valid?: true, data: %{ status: "cart" }, changes: %{ status: "opened" } }) do
    put_change(changeset, :opened_at, Ecto.DateTime.utc())
  end

  defp put_opened_at(changeset), do: changeset

  @doc """
  Balance the order base on the root line items.

  Returns the balanced order.
  """
  def balance(struct) do
    query =
      struct
      |> Ecto.assoc(:root_line_items)
      |> OrderLineItem.Query.root()

    sub_total_cents = Repo.aggregate(query, :sum, :sub_total_cents) || 0
    tax_one_cents = Repo.aggregate(query, :sum, :tax_one_cents) || 0
    tax_two_cents = Repo.aggregate(query, :sum, :tax_two_cents) || 0
    tax_three_cents = Repo.aggregate(query, :sum, :tax_three_cents) || 0
    grand_total_cents = Repo.aggregate(query, :sum, :grand_total_cents) || 0
    authorization_total_cents = Repo.aggregate(query, :sum, :authorization_total_cents) || 0

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

    changeset = change(
      struct,
      sub_total_cents: sub_total_cents,
      tax_one_cents: tax_one_cents,
      tax_two_cents: tax_two_cents,
      tax_three_cents: tax_three_cents,
      grand_total_cents: grand_total_cents,
      authorization_total_cents: authorization_total_cents,
      is_estimate: is_estimate
    )
    Repo.update!(changeset)
  end

  @doc """
  Refresh the payment status of the order. Returns the updated order.
  """
  def refresh_payment_status(order) do
    order
    |> change(payment_status: get_payment_status(order))
    |> Repo.update!()
  end

  @doc """
  Returns the payment status of the given order base on its payments.

  It will always return the correct payment status where as the `payment_status`
  field of the order may not be up to date yet.
  """
  def get_payment_status(order) do
    payments = BalanceService.list_payment_for_target("Order", order.id)

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
      total_authorized_amount_cents == 0 && total_paid_amount_cents == 0 -> "pending"

      total_paid_amount_cents >= order.grand_total_cents && total_gross_amount_cents <= 0 -> "refunded"
      total_authorized_amount_cents == 0 && total_gross_amount_cents == 0 -> "refunded"

      total_paid_amount_cents >= order.grand_total_cents && total_gross_amount_cents < order.grand_total_cents -> "partially_refunded"
      total_paid_amount_cents >= order.grand_total_cents && total_gross_amount_cents == order.grand_total_cents -> "paid"
      total_paid_amount_cents >= order.grand_total_cents && total_gross_amount_cents > order.grand_total_cents -> "over_paid"
      total_paid_amount_cents > 0 -> "partially_paid"
      total_authorized_amount_cents >= order.authorization_total_cents -> "authorized"
      total_authorized_amount_cents > 0 -> "partially_authorized"
      true -> "pending"
    end
  end

  def leaf_line_items(struct) do
    Ecto.assoc(struct, :line_items)
    |> OrderLineItem.Query.leaf()
    |> Repo.all()
  end

  def lock_stock(_) do
    {:ok, nil}
  end

  def lock_shipping_date(_) do
    {:ok, nil}
  end

  #
  # MARK: External Resources
  #
  def get_customer(%{ customer_id: nil }), do: nil
  def get_customer(%{ customer_id: customer_id, customer: nil }), do: CrmService.get_customer(customer_id)
  def get_customer(%{ customer: customer }), do: customer

  use BlueJet.FileStorage.Macro,
    put_external_resources: :external_file_collection,
    field: :external_file_collections,
    owner_type: "Order"

  def put_external_resources(order, {:customer, nil}, _) do
    %{ order | customer: get_customer(order) }
  end

  def put_external_resources(order, _, _), do: order

  #####
  # Business Functions
  #####

  @doc """
  Process the given `order` so that other related resource can be created/updated.

  This function may change the order in database.
  """
  def process(order), do: {:ok, order}

  def process(order, changeset = %{ data: %{ status: "cart" }, changes: %{ status: "opened" } }) do
    order = %{ order | account: IdentityService.get_account(order) }
    order =
      order
      |> put_external_resources({:customer, nil}, %{ account: order.account, locale: order.account.default_locale })
      |> process_leaf_line_items(changeset)
      |> process_auto_fulfill()
      |> refresh_fulfillment_status()

    {:ok, order}
  end

  def process(order, _), do: {:ok, order}

  defp process_leaf_line_items(order, changeset) do
    leaf_line_items =
      OrderLineItem.Query.default()
      |> OrderLineItem.Query.for_order(order.id)
      |> OrderLineItem.Query.leaf()
      |> Repo.all()

    Enum.each(leaf_line_items, fn(line_item) ->
      OrderLineItem.process(line_item, order, changeset)
    end)

    order
  end

  defp process_auto_fulfill(order) do
    af_line_items =
      OrderLineItem
      |> OrderLineItem.Query.for_order(order.id)
      |> OrderLineItem.Query.with_auto_fulfill()
      |> OrderLineItem.Query.leaf()
      |> Repo.all()

    case length(af_line_items) do
      0 -> {:ok, nil}

      _ ->
        fulfillment = DistributionService.create_fulfillment(%{
          account_id: order.account_id,
          source_id: order.id,
          source_tye: "Order"
        })

        Enum.each(af_line_items, fn(line_item) ->
          translations = Translation.merge_translations(%{}, line_item.translations, ["name"])

          DistributionService.create_fulfillment_line_item(%{
            fulfillment_id: fulfillment.id,
            name: line_item.name,
            status: "fulfilled",
            quantity: line_item.order_quantity,
            source_id: line_item.id,
            source_type: "OrderLineItem",
            goods_id: line_item.source_id,
            goods_type: line_item.source_type,
            translations: translations
          })
        end)
    end

    order
  end

  def refresh_fulfillment_status(order) do
    order
    |> change(fulfillment_status: get_fulfillment_status(order))
    |> Repo.update!()
  end

  def get_fulfillment_status(order) do
    root_line_items =
      OrderLineItem
      |> OrderLineItem.Query.for_order(order.id)
      |> OrderLineItem.Query.root()
      |> Repo.all()

    fulfillable_quantity = length(root_line_items)
    fulfilled_quantity =
      root_line_items
      |> Enum.filter(fn(line_item) -> line_item.fulfillment_status == "fulfilled" end)
      |> length()
    returned_quantity =
      root_line_items
      |> Enum.filter(fn(line_item) -> line_item.fulfillment_status == "returned" end)
      |> length()

    cond do
      returned_quantity >= fulfillable_quantity -> "returned"

      (returned_quantity > 0) && (returned_quantity < fulfillable_quantity) -> "partially_returned"

      fulfilled_quantity >= fulfillable_quantity -> "fulfilled"

      (fulfilled_quantity > 0) && (fulfilled_quantity < fulfillable_quantity) -> "partially_fulfilled"

      true -> "pending"
    end
  end

  defmodule Query do
    use BlueJet, :query

    def default() do
      from(o in Order, order_by: [desc: o.opened_at, desc: o.inserted_at])
    end

    def for_account(query, account_id) do
      from(o in query, where: o.account_id == ^account_id)
    end

    def opened(query) do
      from o in query, where: o.status == "opened"
    end

    def not_cart(query) do
      from(o in query, where: o.status != "cart")
    end

    def preloads({:root_line_items, root_line_item_preloads}, options) do
      [root_line_items: {OrderLineItem.Query.root(), OrderLineItem.Query.preloads(root_line_item_preloads, options)}]
    end

    def preloads(_, _) do
      []
    end
  end
end
