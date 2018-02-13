defmodule BlueJet.Storefront.OrderLineItem do
  use BlueJet, :data

  use Trans, translates: [
    :name,
    :print_name,
    :price_caption,
    :caption,
    :description,
    :custom_data
  ], container: :translations

  alias Decimal, as: D
  alias BlueJet.Catalogue.Price
  alias BlueJet.Storefront.{CatalogueService, CrmService, FulfillmentService}
  alias BlueJet.Storefront.Order
  alias BlueJet.Storefront.OrderLineItem.Proxy

  schema "order_line_items" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :code, :string
    field :name, :string
    field :label, :string

    field :fulfillment_status, :string, default: "pending"

    field :print_name, :string
    field :is_leaf, :boolean, default: true
    field :order_quantity, :integer, default: 1
    field :charge_quantity, :decimal

    field :price_name, :string
    field :price_label, :string
    field :price_caption, :string
    field :price_order_unit, :string
    field :price_charge_unit, :string
    field :price_currency_code, :string
    field :price_charge_amount_cents, :integer
    field :price_estimate_average_percentage, :decimal
    field :price_estimate_maximum_percentage, :decimal
    field :price_estimate_by_default, :boolean
    field :price_tax_one_percentage, :decimal
    field :price_tax_two_percentage, :decimal
    field :price_tax_three_percentage, :decimal
    field :price_end_time, Timex.Ecto.DateTime

    field :sub_total_cents, :integer
    field :tax_one_cents, :integer, default: 0
    field :tax_two_cents, :integer, default: 0
    field :tax_three_cents, :integer, default: 0
    field :grand_total_cents, :integer
    field :authorization_total_cents, :integer
    field :is_estimate, :boolean, default: false
    field :auto_fulfill, :boolean

    field :caption, :string
    field :description, :string
    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    field :target_id, Ecto.UUID
    field :target_type, :string
    field :target, :map, virtual: true

    field :product_id, Ecto.UUID
    field :product, :map, virtual: true

    field :price_id, Ecto.UUID
    field :price, :map, virtual: true

    timestamps()

    belongs_to :parent, __MODULE__
    belongs_to :order, Order
    has_many :children, __MODULE__, foreign_key: :parent_id, on_delete: :delete_all
  end

  @type t :: Ecto.Schema.t

  @system_fields [
    :id,
    :account_id,
    :price_name,
    :price_label,
    :price_caption,
    :price_order_unit,
    :price_charge_unit,
    :price_currency_code,
    :price_charge_amount_cents,
    :price_estimate_average_percentage,
    :price_estimate_maximum_percentage,
    :price_estimate_by_default,
    :price_estimate_cents,
    :price_tax_one_percentage,
    :price_tax_two_percentage,
    :price_tax_three_percentage,
    :price_end_time,
    :grand_total_cents,
    :inserted_at,
    :updated_at
  ]

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

  defp required_fields, do: [:order_id, :name, :order_quantity, :charge_quantity, :sub_total_cents, :grand_total_cents, :authorization_total_cents, :auto_fulfill]

  def validate_order_id(changeset = %{ valid?: true, changes: %{ order_id: order_id } }) do
    account_id = get_field(changeset, :account_id)
    order = Repo.get(Order, order_id)

    if order && order.account_id == account_id do
      changeset
    else
      add_error(changeset, :order, "is invalid", [validation: :must_exist])
    end
  end

  def validate_order_id(changeset), do: changeset

  def validate_product_id(changeset = %{ valid?: true, changes: %{ product_id: product_id } }) do
    account = Proxy.get_account(changeset.data)
    product = CatalogueService.get_product(%{ id: product_id }, %{ account: account })

    if product && product.account_id == account.id do
      changeset
    else
      add_error(changeset, :product, "is invalid", [validation: :must_exist])
    end
  end

  def validate_product_id(changeset), do: changeset

  def validate_price_id(changeset = %{ valid?: true, changes: %{ price_id: price_id } }) do
    account = Proxy.get_account(changeset.data)
    product_id = get_field(changeset, :product_id)
    price = get_field(changeset, :price) || CatalogueService.get_price(%{ id: price_id }, %{ account: account })

    if price && price.account_id == account.id && price.product_id == product_id do
      changeset
    else
      add_error(changeset, :price, "is invalid", [validation: :must_exist])
    end
  end

  def validate_price_id(changeset), do: changeset

  @doc """
  Returns the validated changeset.
  """
  def validate(changeset) do
    changeset
    |> validate_required(required_fields())
    |> foreign_key_constraint(:order_id)
    |> foreign_key_constraint(:parent_id)
    |> validate_order_id()
    |> validate_product_id()
    |> validate_price_id()
  end

  defp castable_fields(_, :insert), do: writable_fields()
  defp castable_fields(%{ __meta__: %{ state: :built }}), do: writable_fields()
  defp castable_fields(%{ __meta__: %{ state: :loaded }}), do: writable_fields() -- [:order_id, :product_id, :parent_id]

  defp put_is_leaf(changeset = %{ changes: %{ product_id: _ } }) do
    put_change(changeset, :is_leaf, false)
  end

  defp put_is_leaf(changeset), do: changeset

  defp put_name(changeset = %{ changes: %{ name: _ } }), do: changeset

  defp put_name(changeset = %{ changes: %{ product_id: product_id }}) do
    account = Proxy.get_account(changeset.data)
    product = get_field(changeset, :product) || CatalogueService.get_product(%{ id: product_id }, %{ account: account })
    translations =
      get_field(changeset, :translations)
      |> Translation.merge_translations(product.translations, ["name"])

    changeset
    |> put_change(:product, product)
    |> put_change(:name, product.name)
    |> put_change(:translations, translations)
  end

  defp put_name(changeset), do: changeset

  defp put_print_name(changeset = %{ changes: %{ print_name: _ } }), do: changeset

  defp put_print_name(changeset = %{ data: %{ print_name: nil } }) do
    put_change(changeset, :print_name, get_field(changeset, :name))
  end

  defp put_print_name(changeset), do: changeset

  defp put_price_id(changeset = %{ changes: %{ price_id: _ } }), do: changeset

  defp put_price_id(changeset = %{ changes: %{ product_id: product_id }}) do
    account = Proxy.get_account(changeset.data)

    order_quantity = get_field(changeset, :order_quantity)
    price = get_field(changeset, :price) || CatalogueService.get_price(%{
      product_id: product_id,
      status: "active",
      order_quantity: order_quantity
    }, %{
      account: account
    })

    if price do
      changeset
      |> put_change(:price, price)
      |> put_change(:price_id, price.id)
    else
      changeset
    end
  end

  defp put_price_id(changeset), do: changeset

  defp put_price_fields(changeset = %{ changes: %{ price_id: price_id } }) do
    account = Proxy.get_account(changeset.data)
    price = get_field(changeset, :price) || CatalogueService.get_price(%{ id: price_id }, %{ account: account })
    changeset =
      changeset
      |> put_change(:price, price)
      |> put_change(:price_name, price.name)
      |> put_change(:price_label, price.label)
      |> put_change(:price_caption, price.caption)
      |> put_change(:price_order_unit, price.order_unit)
      |> put_change(:price_charge_unit, price.charge_unit)
      |> put_change(:price_currency_code, price.currency_code)
      |> put_change(:price_charge_amount_cents, price.charge_amount_cents)
      |> put_change(:price_estimate_average_percentage, price.estimate_average_percentage)
      |> put_change(:price_estimate_maximum_percentage, price.estimate_maximum_percentage)
      |> put_change(:price_estimate_by_default, price.estimate_by_default)
      |> put_change(:price_tax_one_percentage, price.tax_one_percentage)
      |> put_change(:price_tax_two_percentage, price.tax_two_percentage)
      |> put_change(:price_tax_three_percentage, price.tax_three_percentage)
      |> put_change(:price_end_time, price.end_time)

    translations =
      get_field(changeset, :translations)
      |> Translation.merge_translations(price.translations, ["name", "caption"], "price_")

    put_change(changeset, :translations, translations)
  end

  defp put_price_fields(changeset), do: changeset

  defp put_is_estimate(changeset = %{ changes: %{ is_estimate: _ } }) do
    changeset
  end

  defp put_is_estimate(changeset = %{ data: %{ id: nil } }) do
    price_estimate_by_default = get_field(changeset, :price_estimate_by_default)
    charge_quantity = get_field(changeset, :charge_quantity)
    cond do
      price_estimate_by_default && !charge_quantity -> put_change(changeset, :is_estimate, true)
      true -> put_change(changeset, :is_estimate, false)
    end
  end

  defp put_is_estimate(changeset), do: changeset

  defp put_charge_quantity(changeset = %{ changes: %{ charge_quantity: _ } }) do
    changeset
  end

  defp put_charge_quantity(changeset = %{ changes: %{ sub_total_cents: sub_total_cents } }) when not is_nil(sub_total_cents) do
    price_charge_amount_cents = get_field(changeset, :price_charge_amount_cents)

    if price_charge_amount_cents do
      charge_quantity = D.div(D.new(sub_total_cents), D.new(price_charge_amount_cents))
      put_change(changeset, :charge_quantity, charge_quantity)
    else
      put_change(changeset, :charge_quantity, D.new(get_field(changeset, :order_quantity)))
    end
  end

  defp put_charge_quantity(changeset) do
    price_estimate_by_default = get_field(changeset, :price_estimate_by_default)
    is_estimate = get_field(changeset, :is_estimate)

    cond do
      price_estimate_by_default && !is_estimate ->
        sub_total_cents = get_field(changeset, :sub_total_cents)
        price_charge_amount_cents = get_field(changeset, :price_charge_amount_cents)
        charge_quantity = D.div(D.new(sub_total_cents), D.new(price_charge_amount_cents))
        put_change(changeset, :charge_quantity, charge_quantity)

      price_estimate_by_default && is_estimate ->
        price_estimate_average_percentage = D.new(get_field(changeset, :price_estimate_average_percentage))
        price_estimate_average_rate = D.div(price_estimate_average_percentage, D.new(100))
        order_quantity = get_field(changeset, :order_quantity)

        charge_quantity = D.mult(D.new(order_quantity), price_estimate_average_rate)
        put_change(changeset, :charge_quantity, charge_quantity)

      !price_estimate_by_default ->
        put_change(changeset, :charge_quantity, D.new(get_field(changeset, :order_quantity)))

      true -> changeset
    end
  end

  defp put_amount_fields(changeset = %{
    action: :update,
    data: %{ price_id: price_id },
    changes: %{ price_id: nil }})
  when not is_nil(price_id) do
    changeset
  end

  defp put_amount_fields(changeset = %{
    action: :update,
    data: %{ price_id: price_id } })
  when not is_nil(price_id) do
    put_amount_fields(changeset, :with_price)
  end

  defp put_amount_fields(changeset = %{ action: :insert, changes: %{ price_id: _ } }) do
    put_amount_fields(changeset, :with_price)
  end

  defp put_amount_fields(changeset) do
    put_amount_fields(changeset, :no_price)
  end

  defp put_amount_fields(changeset = %{ changes: %{ target_id: target_id, target_type: "PointTransaction" } }, :no_price) do
    account = Proxy.get_account(changeset.data)
    point_transaction = CrmService.get_point_transaction(%{ id: target_id }, %{ account: account })
    sub_total_cents = point_transaction.amount

    changeset
    |> put_change(:sub_total_cents, sub_total_cents)
    |> put_change(:tax_one_cents, 0)
    |> put_change(:tax_two_cents, 0)
    |> put_change(:tax_three_cents, 0)
    |> put_change(:grand_total_cents, sub_total_cents)
    |> put_change(:authorization_total_cents, sub_total_cents)
  end

  defp put_amount_fields(changeset, :no_price) do
    sub_total_cents = get_field(changeset, :sub_total_cents)

    if !sub_total_cents do
      changeset
    else
      tax_one_cents = get_field(changeset, :tax_one_cents)
      tax_two_cents = get_field(changeset, :tax_two_cents)
      tax_three_cents = get_field(changeset, :tax_three_cents)
      grand_total_cents = sub_total_cents + tax_one_cents + tax_two_cents + tax_three_cents

      changeset
      |> put_change(:grand_total_cents, grand_total_cents)
      |> put_change(:authorization_total_cents, grand_total_cents)
    end
  end

  defp put_amount_fields(changeset, :with_price) do
    charge_quantity = get_field(changeset, :charge_quantity)
    price_charge_amount_cents = get_field(changeset, :price_charge_amount_cents)

    price_tax_one_percentage = D.new(get_field(changeset, :price_tax_one_percentage))
    price_tax_two_percentage = D.new(get_field(changeset, :price_tax_two_percentage))
    price_tax_three_percentage = D.new(get_field(changeset, :price_tax_three_percentage))

    price_tax_one_rate = D.div(price_tax_one_percentage, D.new(100))
    price_tax_two_rate = D.div(price_tax_two_percentage, D.new(100))
    price_tax_three_rate = D.div(price_tax_three_percentage, D.new(100))

    is_estimate = get_field(changeset, :is_estimate)

    sub_total_cents = get_field(changeset, :sub_total_cents) || price_charge_amount_cents |> D.new() |> D.mult(charge_quantity) |> D.round() |> D.to_integer()
    tax_one_cents = get_change(changeset, :tax_one_cents) || sub_total_cents |> D.new() |> D.mult(price_tax_one_rate) |> D.round() |> D.to_integer()
    tax_two_cents = get_change(changeset, :tax_two_cents) || sub_total_cents |> D.new() |> D.mult(price_tax_two_rate) |> D.round() |> D.to_integer()
    tax_three_cents = get_change(changeset, :tax_three_cents) || sub_total_cents |> D.new() |> D.mult(price_tax_three_rate) |> D.round() |> D.to_integer()

    grand_total_cents = sub_total_cents + tax_one_cents + tax_two_cents + tax_three_cents

    authorization_total_cents = if is_estimate do
      order_quantity = get_field(changeset, :order_quantity)

      price_estimate_maximum_percentage = D.new(get_field(changeset, :price_estimate_maximum_percentage))
      price_estimate_maximum_rate = D.div(price_estimate_maximum_percentage, D.new(100))

      auth_charge_quantity = order_quantity |> D.new() |> D.mult(price_estimate_maximum_rate)
      auth_sub_total_cents = price_charge_amount_cents |> D.new() |> D.mult(auth_charge_quantity) |> D.round() |> D.to_integer()
      auth_tax_one_cents = auth_sub_total_cents |> D.new() |> D.mult(price_tax_one_rate) |> D.round() |> D.to_integer()
      auth_tax_two_cents = auth_sub_total_cents |> D.new() |> D.mult(price_tax_two_rate) |> D.round() |> D.to_integer()
      auth_tax_three_cents = auth_sub_total_cents |> D.new() |> D.mult(price_tax_three_rate) |> D.round() |> D.to_integer()

      auth_sub_total_cents + auth_tax_one_cents + auth_tax_two_cents + auth_tax_three_cents
    else
      grand_total_cents
    end

    changeset
    |> put_change(:sub_total_cents, sub_total_cents)
    |> put_change(:tax_one_cents, tax_one_cents)
    |> put_change(:tax_two_cents, tax_two_cents)
    |> put_change(:tax_three_cents, tax_three_cents)
    |> put_change(:grand_total_cents, grand_total_cents)
    |> put_change(:authorization_total_cents, authorization_total_cents)
  end

  defp put_auto_fulfill(changeset = %{ changes: %{ auto_fulfill: _ } }), do: changeset

  defp put_auto_fulfill(changeset = %{ changes: %{ product_id: product_id } }) do
    account = Proxy.get_account(changeset.data)
    product = get_field(changeset, :product) || CatalogueService.get_product(%{ id: product_id }, %{ account: account })

    changeset
    |> put_change(:product, product)
    |> put_change(:auto_fulfill, product.auto_fulfill)
  end

  defp put_auto_fulfill(changeset = %{ data: %{ auto_fulfill: nil } }) do
    grand_total_cents = get_field(changeset, :grand_total_cents)

    if grand_total_cents >= 0 do
      put_change(changeset, :auto_fulfill, false)
    else
      put_change(changeset, :auto_fulfill, true)
    end
  end

  defp put_auto_fulfill(changeset), do: changeset

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(oli, :insert, params) do
    castable_fields = castable_fields(oli, :insert)

    oli
    |> cast(params, castable_fields)
    |> Map.put(:action, :insert)
    |> put_is_leaf()
    |> put_name()
    |> put_print_name()
    |> put_price_id()
    |> put_price_fields()
    |> put_is_estimate()
    |> put_charge_quantity()
    |> put_amount_fields()
    |> put_auto_fulfill()
    |> validate()
  end

  def changeset(oli, :update, params, locale \\ nil, default_locale \\ nil) do
    oli = %{ oli | account: Proxy.get_account(oli) }
    default_locale = default_locale || oli.account.default_locale
    locale = locale || default_locale

    oli
    |> cast(params, castable_fields(oli))
    |> Map.put(:action, :update)
    |> put_is_leaf()
    |> put_name()
    |> put_print_name()
    |> put_price_id()
    |> put_price_fields()
    |> put_is_estimate()
    |> put_charge_quantity()
    |> put_amount_fields()
    |> put_auto_fulfill()
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  def changeset(oli, :delete) do
    change(oli)
    |> Map.put(:action, :delete)
  end

  @doc """
  Balance the order line item by creating or updating its children.

  If the order line item has parent, then calling this function has the same
  effect as if it is called on the parent. This function will search for the
  root and balance towards the leaf.

  This function will balance the entire branch regardless which order line item
  on the branch is the input.

  Returns the input order line item after its being balanced.
  """
  def balance(oli = %__MODULE__{ is_leaf: true, parent_id: nil }), do: oli

  def balance(oli = %__MODULE__{ is_leaf: true }) do
    parent = assoc(oli, :parent) |> Repo.one()
    balance(parent)
  end

  def balance(oli = %__MODULE__{ product_id: product_id }) when not is_nil(product_id) do
    account = Proxy.get_account(oli)
    product = oli.product || CatalogueService.get_product(%{ id: product_id }, %{ account: account })
    balance_by_product(oli, product)
  end

  def balance(oli), do: oli

  ######
  defp balance_by_product(oli, product = %{ kind: kind }) when kind in ["simple", "item", "variant"] do
    target_order_quantity = product.goods_quantity * oli.order_quantity
    target_charge_quantity = if oli.price_estimate_by_default do
      oli.charge_quantity
    else
      D.new(target_order_quantity)
    end
    oli = %{ oli | product: product }
    goods = Proxy.get_goods(oli)

    # Product variant should ever only have one child
    child = assoc(oli, :children) |> Repo.one()
    child_fields = %{
      account_id: oli.account_id,
      order_id: oli.order_id,
      target_id: product.goods_id,
      target_type: product.goods_type,
      parent_id: oli.id,
      is_leaf: true,
      auto_fulfill: oli.auto_fulfill,
      name: goods.name,
      order_quantity: target_order_quantity,
      charge_quantity: target_charge_quantity,
      sub_total_cents: oli.sub_total_cents,
      tax_one_cents: oli.tax_one_cents,
      tax_two_cents: oli.tax_two_cents,
      tax_three_cents: oli.tax_three_cents,
      grand_total_cents: oli.grand_total_cents,
      authorization_total_cents: oli.authorization_total_cents,
      translations: Translation.merge_translations(%{}, goods.translations, ["name"])
    }

    case child do
      nil -> Repo.insert!(change(%__MODULE__{}, child_fields))

      _ ->
        child
        |> change(child_fields)
        |> Repo.update!()
    end

    oli
  end

  defp balance_by_product(oli, product = %{ kind: kind }) when kind == "combo" do
    price = Repo.get!(Price, oli.price_id) |> Repo.preload(:children)
    items = assoc(product, :items) |> Repo.all()

    Enum.each(items, fn(item) ->
      existing_child = Repo.get_by(__MODULE__, parent_id: oli.id, product_id: item.id)
      child = case existing_child do
        nil -> %__MODULE__{ account_id: oli.account_id }

        _ -> existing_child
      end

      target_price = Enum.find(price.children, fn(child_price) ->
        child_price.product_id == item.id
      end)
      changeset = __MODULE__.changeset(child, %{
        "auto_fulfill" => oli.auto_fulfill,
        "order_id" => oli.order_id,
        "product_id" => item.id,
        "order_quantity" => oli.order_quantity,
        "parent_id" => oli.id,
        "price_id" => target_price.id
      })

      updated_child = case existing_child do
        nil -> Repo.insert!(changeset)

        _ -> Repo.update!(changeset)
      end

      __MODULE__.balance(updated_child)
    end)

    oli
  end

  # def auto_fulfill(%{ auto_fulfill: false }, _), do: nil

  # def auto_fulfill(line_item = %{ target_type: nil }, fulfillment) do
  #   Proxy.create_fulfillment_line_item(line_item, fulfillment)
  # end

  # def auto_fulfill(line_item = %{ target_type: "Unlockable", target_id: target_id }, fulfillment) do
  #   line_item = Repo.preload(line_item, :order)

  #   %Unlock{ account_id: line_item.account_id }
  #   |> change(%{
  #       unlockable_id: target_id,
  #       customer_id: line_item.order.customer_id,
  #       target_id: line_item.id,
  #       target_type: "OrderLineItem"
  #      })
  #   |> Repo.insert!()

  #   Proxy.create_fulfillment_line_item(line_item, fulfillment)
  # end

  # def auto_fulfill(line_item = %{ target_type: "Depositable" }, fulfillment) do
  #   line_item = Repo.preload(line_item, :order)
  #   depositable = Proxy.get_depositable(line_item)

  #   if depositable.target_type == "PointAccount" do
  #     Proxy.create_point_transaction(%{
  #       status: "committed",
  #       amount: line_item.order_quantity * depositable.amount,
  #       reason_label: "deposit_by_depositable"
  #     }, line_item)
  #   end

  #   Proxy.create_fulfillment_line_item(line_item, fulfillment)
  # end

  # def auto_fulfill(line_item = %{ target_type: "PointTransaction", target_id: target_id }, fulfillment) do
  #   Proxy.commit_point_transaction(target_id, line_item)
  #   Proxy.create_fulfillment_line_item(line_item, fulfillment)
  # end

  @doc """
  Process the given order line item so that other related retarget can be created/updated.

  This function may change the order line item in database.

  External retargets maybe created/updated.

  Returns the processed order line item.
  """
  def process(line_item, %{ action: action }) when action in [:insert, :update] do
    line_item =
      line_item
      |> Repo.preload(:order)
      |> __MODULE__.balance()

    line_item.order
    |> Order.balance()
    |> Order.refresh_payment_status()

    {:ok, line_item}
  end

  def process(line_item, %{ action: :delete }) do
    line_item = Repo.preload(line_item, :order)

    line_item.order
    |> Order.balance()
    |> Order.refresh_payment_status()

    {:ok, line_item}
  end

  @doc """
  Refresh the fulfillment status of the order line item. Returns the updated
  fulfillment status.
  """
  def refresh_fulfillment_status(oli) do
    oli
    |> change(fulfillment_status: get_fulfillment_status(oli))
    |> Repo.update!()

    if oli.parent_id do
      assoc(oli, :parent)
      |> Repo.one()
      |> refresh_fulfillment_status()

      oli
    else
      assoc(oli, :order)
      |> Repo.one()
      |> Order.refresh_fulfillment_status()
    end
  end

  @doc """
  Returns the fulfillment status of the order line item base on its fulfillment.

  It will always return the correct fulfillment status where as the `fulfillment_status`
  field of the order line item may not be up to date yet.
  """
  def get_fulfillment_status(%{ grand_total_cents: grand_total_cents }) when grand_total_cents < 0 do
    "fulfilled"
  end

  def get_fulfillment_status(oli = %{ is_leaf: true }) do
    fulfillment_items = FulfillmentService.list_fulfillment_item(%{ target_type: "OrderLineItem", target_id: oli.id }, %{ account_id: oli.account_id })

    fulfillable_quantity = oli.order_quantity
    fulfilled_quantity =
      fulfillment_items
      |> Enum.filter(fn(fli) -> fli.status == "fulfilled" end)
      |> Enum.map(fn(fli) -> fli.quantity end)
      |> Enum.sum()

    returned_quantity =
      fulfillment_items
      |> Enum.filter(fn(fli) -> fli.status == "returned" end)
      |> Enum.map(fn(fli) -> fli.quantity end)
      |> Enum.sum()

    cond do
      returned_quantity >= fulfillable_quantity -> "returned"

      (returned_quantity > 0) && (returned_quantity < fulfillable_quantity) -> "partially_returned"

      fulfilled_quantity >= fulfillable_quantity -> "fulfilled"

      (fulfilled_quantity > 0) && (fulfilled_quantity < fulfillable_quantity) -> "partially_fulfilled"

      true -> "pending"
    end
  end

  def get_fulfillment_status(oli) do
    children = assoc(oli, :children) |> Repo.all()

    fulfillable_quantity = length(children)
    fulfilled_quantity =
      children
      |> Enum.filter(fn(child) -> child.fulfillment_status == "fulfilled" end)
      |> length()
    returned_quantity =
      children
      |> Enum.filter(fn(child) -> child.fulfillment_status == "returned" end)
      |> length()

    cond do
      returned_quantity >= fulfillable_quantity -> "returned"

      (returned_quantity > 0) && (returned_quantity < fulfillable_quantity) -> "partially_returned"

      fulfilled_quantity >= fulfillable_quantity -> "fulfilled"

      (fulfilled_quantity > 0) && (fulfilled_quantity < fulfillable_quantity) -> "partially_fulfilled"

      true -> "pending"
    end
  end
end
