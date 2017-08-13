defmodule BlueJet.Storefront.OrderLineItem do
  use BlueJet, :data

  use Trans, translates: [:name, :print_name, :description, :price_caption, :custom_data], container: :translations

  alias Ecto.Changeset
  alias BlueJet.Translation
  alias BlueJet.Storefront.OrderLineItem

  alias BlueJet.Storefront.Product
  alias BlueJet.Storefront.ProductItem
  alias BlueJet.Storefront.Order
  alias BlueJet.Storefront.Price
  alias BlueJet.Storefront.Unlockable
  alias BlueJet.Storefront.Sku
  alias BlueJet.Identity.Account

  schema "order_line_items" do
    field :name, :string
    field :label, :string
    field :print_name, :string
    field :description, :string

    field :is_leaf, :boolean, default: false
    field :is_estimate, :boolean, default: false

    field :price_name, :string
    field :price_label, :string
    field :price_caption, :string
    field :price_order_unit, :string
    field :price_charge_unit, :string
    field :price_currency_code, :string
    field :price_charge_amount_cents, Money.Ecto.Type
    field :price_estimate_average_ratio, :decimal
    field :price_estimate_maximum_ratio, :decimal
    field :price_estimate_by_default, :boolean
    field :price_tax_one_rate, :integer
    field :price_tax_two_rate, :integer
    field :price_tax_three_rate, :integer
    field :price_end_time, :utc_datetime

    field :charge_quantity, :decimal
    field :order_quantity, :integer, default: 1

    field :sub_total_cents, Money.Ecto.Type, default: %Money{ amount: 0 }
    field :tax_one_cents, Money.Ecto.Type, default: %Money{ amount: 0 }
    field :tax_two_cents, Money.Ecto.Type, default: %Money{ amount: 0 }
    field :tax_three_cents, Money.Ecto.Type, default: %Money{ amount: 0 }
    field :grand_total_cents, Money.Ecto.Type, default: %Money{ amount: 0 }

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    timestamps()

    belongs_to :account, Account
    belongs_to :order, Order
    belongs_to :price, Price
    belongs_to :product, Product
    belongs_to :product_item, ProductItem
    belongs_to :parent, OrderLineItem
    belongs_to :sku, Sku
    belongs_to :unlockable, Unlockable
    has_many :children, OrderLineItem, foreign_key: :parent_id
  end

  def system_fields do
    [
      :id,
      :price_name,
      :price_label,
      :price_caption,
      :price_order_unit,
      :price_charge_unit,
      :price_currency_code,
      :price_charge_cents,
      :price_estimate_cents,
      :price_tax_one_rate,
      :price_tax_two_rate,
      :price_tax_three_rate,
      :price_end_time,
      :grand_total_cents,
      :sku_id,
      :unlockable_id,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    OrderLineItem.__schema__(:fields) -- system_fields()
  end

  def translatable_fields do
    OrderLineItem.__trans__(:fields)
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:account_id, :order_id, :product_id, :product_item_id, :parent_id, :sku_id, :unlockable_id]
  end

  def require_fields do
    [
      :account_id,
      :order_id,
      :is_estimate
    ]
  end

  def validate(changeset) do
    changeset
    |> validate_required(require_fields())
    |> foreign_key_constraint(:account_id)
    |> validate_assoc_account_scope([:order, :price, :product, :product_item, :parent, :sku, :unlockable])
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}, locale \\ "en") do
    struct
    |> cast(params, castable_fields(struct))
    |> validate()
    |> put_is_leaf()
    |> put_name()
    |> put_is_estimate()
    |> put_price_id()
    |> put_price_fields()
    |> put_charge_quantity()
    |> put_amount_fields()
    |> Translation.put_change(translatable_fields(), locale)
  end

  def put_is_leaf(changeset = %Changeset{ valid?: true, changes: %{ sku_id: sku_id } }) do
    put_change(changeset, :is_leaf, true)
  end
  def put_is_leaf(changeset = %Changeset{ valid?: true, changes: %{ unlockable_id: unlockable_id } }) do
    put_change(changeset, :is_leaf, true)
  end
  def put_is_leaf(changeset), do: changeset

  def put_name(changeset = %Changeset{ valid?: true, changes: %{ name: name } }) do
    changeset
  end
  def put_name(changeset = %Changeset{ valid?: true, changes: %{ product_item_id: product_item_id }}) do
    product_item = Repo.get!(ProductItem, product_item_id)
    translations =
      Changeset.get_field(changeset, :translations)
      |> Translation.merge_translations(product_item.translations, ["name"])

    changeset
    |> put_change(:name, product_item.name)
    |> put_change(:translations, translations)
  end
  def put_name(changeset = %Changeset{ valid?: true, changes: %{ product_id: product_id }}) do
    product = Repo.get!(Product, product_id)
    translations =
      Changeset.get_field(changeset, :translations)
      |> Translation.merge_translations(product.translations, ["name"])

    changeset
    |> put_change(:name, product.name)
    |> put_change(:translations, translations)
  end
  def put_name(changeset = %Changeset{ valid?: true, changes: %{ sku_id: sku_id }}) do
    sku = Repo.get!(Sku, sku_id)
    translations =
      Changeset.get_field(changeset, :translations)
      |> Translation.merge_translations(sku.translations, ["name"])

    changeset
    |> put_change(:name, sku.name)
    |> put_change(:translations, translations)
  end
  def put_name(changeset = %Changeset{ valid?: true, changes: %{ unlockable_id: unlockable_id }}) do
    unlockable = Repo.get!(Unlockable, unlockable_id)
    translations =
      Changeset.get_field(changeset, :translations)
      |> Translation.merge_translations(unlockable.translations, ["name"])

    changeset
    |> put_change(:name, unlockable.name)
    |> put_change(:translations, translations)
  end
  def put_name(changeset), do: changeset

  def put_is_estimate(changeset = %Changeset{ valid?: true, changes: %{ is_estimate: is_estimate } }) do
    changeset
  end
  def put_is_estimate(changeset = %Changeset{ valid?: true }) do
    price_estimate_by_default = Changeset.get_field(changeset, :price_estimate_by_default)
    charge_quantity = Changeset.get_field(changeset, :charge_quantity)
    cond do
      price_estimate_by_default && !charge_quantity -> put_change(changeset, :is_estimate, true)
      true -> put_change(changeset, :is_estimate, false)
    end
  end
  def put_is_estimate(changeset), do: changeset

  def put_price_id(changeset = %Changeset{ valid?: true, changes: %{ product_item_id: product_item_id }}) do
    price_id = get_change(changeset, :price_id)

    if !price_id do
      order_quantity = get_change(changeset, :order_quantity)
      price = Price.query_for(product_item_id: product_item_id, order_quantity: order_quantity) |> Repo.one()
      put_change(changeset, :price_id, price.id)
    else
      changeset
    end
  end
  def put_price_id(changeset), do: changeset

  # Add in inventory related fields to make inventory tracking easier
  def put_inventory_fields(changeset = %Changeset{ valid?: true, changes: %{ product_item_id: product_item_id } }) do
    product_item = Repo.get(ProductItem, product_item_id)

    changeset
    |> put_change(:sku_id, product_item.sku_id)
    |> put_change(:unlockable_id, product_item.unlockable_id)
  end
  def put_inventory_fields(changeset), do: changeset

  def put_price_fields(changeset = %Changeset{ valid?: true, changes: %{ price_id: price_id } }) do
    price = Repo.get!(Price, price_id)
    changeset =
      changeset
      |> put_change(:price_name, price.name)
      |> put_change(:price_label, price.label)
      |> put_change(:price_caption, price.caption)
      |> put_change(:price_order_unit, price.order_unit)
      |> put_change(:price_charge_unit, price.charge_unit)
      |> put_change(:price_currency_code, price.currency_code)
      |> put_change(:price_charge_amount_cents, price.charge_amount_cents)
      |> put_change(:price_estimate_average_ratio, price.estimate_average_ratio)
      |> put_change(:price_estimate_maximum_ratio, price.estimate_maximum_ratio)
      |> put_change(:price_estimate_by_default, price.estimate_by_default)
      |> put_change(:price_tax_one_rate, price.tax_one_rate)
      |> put_change(:price_tax_two_rate, price.tax_two_rate)
      |> put_change(:price_tax_three_rate, price.tax_three_rate)
      |> put_change(:price_end_time, price.end_time)

    translations =
      Changeset.get_field(changeset, :translations)
      |> Translation.merge_translations(price.translations, ["name", "caption"], "price_")

    put_change(changeset, :translations, translations)
  end
  def put_price_fields(changeset), do: changeset

  def put_charge_quantity(changeset = %Changeset{ valid?: true, changes: %{ charge_quantity: charge_quantity } }) do
    changeset
  end
  def put_charge_quantity(changeset = %Changeset{ valid?: true }) do
    price_estimate_by_default = Changeset.get_field(changeset, :price_estimate_by_default)
    is_estimate = Changeset.get_field(changeset, :is_estimate)

    cond do
      price_estimate_by_default && !is_estimate ->
        sub_total_cents = Changeset.get_field(changeset, :sub_total_cents)
        price_charge_cents = Changeset.get_field(changeset, :price_charge_cents)
        charge_quantity = Decimal.div(Decimal.new(sub_total_cents), Decimal.new(price_charge_cents))
        put_change(changeset, :charge_quantity, charge_quantity)

      price_estimate_by_default && is_estimate ->
        price_estimate_average_ratio = Changeset.get_field(changeset, :price_estimate_average_ratio)
        order_quantity = Changeset.get_field(changeset, :order_quantity)
        charge_quantity = Decimal.new(order_quantity) * price_estimate_average_ratio
        put_change(changeset, :charge_quantity, charge_quantity)

      !price_estimate_by_default ->
        put_change(changeset, :charge_quantity, Changeset.get_field(changeset, :order_quantity))

      true -> changeset
    end
  end
  def put_charge_quantity(changeset), do: changeset

  def put_amount_fields(changeset = %Changeset{ valid?: true, changes: %{ product_id: product_id } }) do
    order_quantity = Changeset.get_field(changeset, :order_quantity)
    charge_quantity = Changeset.get_field(changeset, :charge_quantity)
    product_item_ids = ProductItem.query_for(product_id: product_id) |> select([pi], pi.id) |> Repo.all()
    prices = Price.for(product_item_ids: product_item_ids, order_quantity: order_quantity) |> Repo.all()

    sub_total_cents = Enum.reduce(prices, %Money{}, fn(price, acc) ->
      price.charge_amount_cents
      |> Money.multiply(charge_quantity)
      |> Money.add(acc)
    end)

    tax_one_cents = Enum.reduce(prices, %Money{}, fn(price, acc) ->
      price.charge_amount_cents
      |> Money.multiply(price.tax_one_rate / 100)
      |> Money.multiply(charge_quantity)
      |> Money.add(acc)
    end)
    tax_two_cents = Enum.reduce(prices, %Money{}, fn(price, acc) ->
      price.charge_amount_cents
      |> Money.multiply(price.tax_two_rate / 100)
      |> Money.multiply(charge_quantity)
      |> Money.add(acc)
    end)
    tax_three_cents = Enum.reduce(prices, %Money{}, fn(price, acc) ->
      price.charge_amount_cents
      |> Money.multiply(price.tax_three_rate / 100)
      |> Money.multiply(charge_quantity)
      |> Money.add(acc)
    end)

    grand_total_cents =
      sub_total_cents
      |> Money.add(tax_one_cents)
      |> Money.add(tax_two_cents)
      |> Money.add(tax_three_cents)

    changeset
    |> put_change(:sub_total_cents, sub_total_cents)
    |> put_change(:tax_one_cents, tax_one_cents)
    |> put_change(:tax_two_cents, tax_two_cents)
    |> put_change(:tax_three_cents, tax_three_cents)
    |> put_change(:grand_total_cents, grand_total_cents)
  end
  def put_amount_fields(changeset = %Changeset{ valid?: true, changes: %{ product_item_id: product_item_id } }) do
    charge_quantity = Changeset.get_field(changeset, :charge_quantity)
    price_charge_amount_cents = Changeset.get_field(changeset, :price_charge_amount_cents)

    sub_total_cents = Changeset.get_field(changeset, :sub_total_cents) || price_charge_amount_cents * charge_quantity
    changed_keys = Map.keys(changeset.changes)
    BlueJet.Utils.intersect_list(changed_keys, [:price_charge_cents])
  end
  def put_amount_fields(changeset), do: changeset

  def root(query) do
    from oli in query, where: is_nil(oli.parent_id)
  end

  def balance!(struct = %OrderLineItem{ is_leaf: true, parent_id: nil }), do: struct
  def balance!(struct = %OrderLineItem{ is_leaf: true }) do
    parent = assoc(struct, :parent) |> Repo.one()
    balance!(parent)
  end
  def balance!(struct = %OrderLineItem{ product_item_id: product_item_id, parent_id: nil }) when not is_nil(product_item_id) do
    children_count = assoc(struct, :children) |> Repo.aggregate(:count, :id)
    struct = enforce_children_count!(struct, struct.order_quantity - children_count)

    sub_total_cents = div(struct.sub_total_cents, struct.order_quantity)
    tax_one_cents = div(struct.tax_one_cents, struct.order_quantity)
    tax_two_cents = div(struct.tax_two_cents, struct.order_quantity)
    tax_three_cents = div(struct.tax_three_cents, struct.order_quantity)
    grand_total_cents = div(struct.grand_total_cents, struct.order_quantity)

    assoc(struct, :children) |> Repo.update_all(
      set: [
        sub_total_cents: sub_total_cents,
        tax_one_cents: tax_one_cents,
        tax_two_cents: tax_two_cents,
        tax_three_cents: tax_three_cents,
        grand_total_cents: grand_total_cents
      ]
    )

    struct
  end
  # TODO:
  def balance!(struct = %OrderLineItem{ product_id: product_id, parent_id: nil }) when not is_nil(product_id) do
    product = Repo.get!(Product, product_id)
    product_items = assoc(product, :items) |> Repo.all()

    Enum.each(product_items, fn(product_item) ->

    end)
  end

  defp enforce_children_count!(struct, 0), do: struct
  defp enforce_children_count!(struct, count) when count > 0 do
    for _ <- 1..count do
      source = struct |> Map.drop(OrderLineItem.__schema__(:associations)) |> Map.drop([:__meta__, :__struct__, :inserted_at, :updated_at, :id, :is_leaf, :parent_id, :order_quantity])

      child = Map.merge(%OrderLineItem{}, source)
      child = %{ child |
        parent_id: struct.id,
        is_leaf: true,
        order_quantity: 1
      }
      Repo.insert!(child)
    end

    struct
  end
  defp enforce_children_count!(struct, count) when count < 0 do
    for _ <- 1..abs(count) do
      child = assoc(struct, :children) |> first() |> Repo.one()
      Repo.delete!(child)
    end

    struct
  end
end
