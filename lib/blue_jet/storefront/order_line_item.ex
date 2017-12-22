defmodule BlueJet.Storefront.OrderLineItem do
  use BlueJet, :data

  use Trans, translates: [:name, :print_name, :description, :price_caption, :custom_data], container: :translations

  alias Decimal, as: D
  alias Ecto.Changeset

  alias BlueJet.AccessRequest
  alias BlueJet.Translation

  alias BlueJet.Goods
  alias BlueJet.CRM

  alias BlueJet.Catalogue.Product
  alias BlueJet.Catalogue.Price

  alias BlueJet.Storefront.OrderLineItem
  alias BlueJet.Storefront.Order
  alias BlueJet.Storefront.Unlock

  schema "order_line_items" do
    field :account_id, Ecto.UUID
    field :name, :string
    field :label, :string
    field :print_name, :string
    field :description, :string

    field :is_leaf, :boolean, default: true
    field :is_estimate, :boolean, default: false

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

    field :charge_quantity, :decimal
    field :order_quantity, :integer

    field :sub_total_cents, :integer
    field :tax_one_cents, :integer
    field :tax_two_cents, :integer
    field :tax_three_cents, :integer
    field :grand_total_cents, :integer
    field :authorization_toal_cents, :integer

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    field :source_id, Ecto.UUID
    field :source_type, :string

    timestamps()

    belongs_to :order, Order
    belongs_to :price, Price
    belongs_to :product, Product
    belongs_to :parent, OrderLineItem
    has_many :children, OrderLineItem, foreign_key: :parent_id, on_delete: :delete_all
  end

  def source(account_id, source_id, "Stockable") do
    response = Goods.do_get_stockable(%AccessRequest{
      vas: %{ account_id: account_id },
      params: %{ "id" => source_id }
    })

    case response do
      {:ok, %{ data: stockable }} -> stockable
      {:error, _} -> nil
    end
  end
  def source(account_id, source_id, "Unlockable") do
    response = Goods.do_get_unlockable(%AccessRequest{
      vas: %{ account_id: account_id },
      params: %{ "id" => source_id }
    })

    case response do
      {:ok, %{ data: unlockable }} -> unlockable
      {:error, _} -> nil
    end
  end
  def source(account_id, source_id, "Depositable") do
    response = Goods.do_get_depositable(%AccessRequest{
      vas: %{ account_id: account_id },
      params: %{ "id" => source_id }
    })

    case response do
      {:ok, %{ data: depositable }} -> depositable
      {:error, _} -> nil
    end
  end
  def source(account_id, source_id, "PointTransaction") do
    response = CRM.do_get_point_transaction(%AccessRequest{
      vas: %{ account_id: account_id },
      params: %{ "id" => source_id }
    })

    case response do
      {:ok, %{ data: point_transaction }} -> point_transaction
      {:error, _} -> nil
    end
  end
  def source(_, _, _), do: nil
  def source(%OrderLineItem{ account_id: account_id, source_id: source_id, source_type: source_type }) do
    source(account_id, source_id, source_type)
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
      :price_charge_amount_cents,
      :price_estimate_cents,
      :price_tax_one_percentage,
      :price_tax_two_percentage,
      :price_tax_three_percentage,
      :price_end_time,
      :grand_total_cents,
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
    writable_fields() -- [:account_id, :order_id, :product_id, :parent_id]
  end

  def require_fields(changeset) do
    common = [:account_id, :order_id, :order_quantity]

    cond do
      get_field(changeset, :product_id) ->
        common
      get_field(changeset, :source_type) == "PointTransaction" ->
        common
      true ->
        common ++ [:sub_total_cents]
    end
  end

  def validate(changeset) do
    changeset
    |> validate_required(require_fields(changeset))
    |> foreign_key_constraint(:account_id)
    |> foreign_key_constraint(:order_id)
    |> foreign_key_constraint(:price_id)
    |> foreign_key_constraint(:product_id)
    |> foreign_key_constraint(:parent_id)
    |> validate_assoc_account_scope([:order, :price, :product, :parent])
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

  def put_is_leaf(changeset = %Changeset{ valid?: true, changes: %{ product_id: _ } }) do
    put_change(changeset, :is_leaf, false)
  end
  def put_is_leaf(changeset), do: changeset

  def put_name(changeset = %Changeset{ valid?: true, changes: %{ name: _ } }) do
    changeset
  end
  def put_name(changeset = %Changeset{ valid?: true, changes: %{ product_id: product_id }}) do
    product = Repo.get!(Product, product_id)
    translations =
      get_field(changeset, :translations)
      |> Translation.merge_translations(product.translations, ["name"])

    changeset
    |> put_change(:name, product.name)
    |> put_change(:translations, translations)
  end
  def put_name(changeset), do: changeset

  def put_is_estimate(changeset = %Changeset{ valid?: true, changes: %{ is_estimate: _ } }) do
    changeset
  end
  def put_is_estimate(changeset = %Changeset{ valid?: true, data: %OrderLineItem{ id: nil } }) do
    price_estimate_by_default = get_field(changeset, :price_estimate_by_default)
    charge_quantity = get_field(changeset, :charge_quantity)
    cond do
      price_estimate_by_default && !charge_quantity -> put_change(changeset, :is_estimate, true)
      true -> put_change(changeset, :is_estimate, false)
    end
  end
  def put_is_estimate(changeset), do: changeset

  def put_price_id(changeset = %Changeset{ valid?: true, changes: %{ price_id: _ } }), do: changeset
  def put_price_id(changeset = %Changeset{ valid?: true, changes: %{ product_id: product_id }}) do
    order_quantity = get_change(changeset, :order_quantity)
    price = Price.query_for(product_id: product_id, order_quantity: order_quantity) |> Repo.one()
    put_change(changeset, :price_id, price.id)
  end
  def put_price_id(changeset), do: changeset

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
  def put_price_fields(changeset), do: changeset

  def put_charge_quantity(changeset = %Changeset{ valid?: true, changes: %{ charge_quantity: _ } }) do
    changeset
  end
  def put_charge_quantity(changeset = %Changeset{ valid?: true, changes: %{ sub_total_cents: sub_total_cents } }) when not is_nil(sub_total_cents) do
    price_charge_amount_cents = get_field(changeset, :price_charge_amount_cents)

    if price_charge_amount_cents do
      charge_quantity = D.div(D.new(sub_total_cents), D.new(price_charge_amount_cents))
      put_change(changeset, :charge_quantity, charge_quantity)
    else
      put_change(changeset, :charge_quantity, D.new(get_field(changeset, :order_quantity)))
    end
  end
  def put_charge_quantity(changeset = %Changeset{ valid?: true }) do
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
  def put_charge_quantity(changeset), do: changeset

  def put_amount_fields(changeset = %Changeset{ valid?: true }) do
    if get_field(changeset, :price_id) do
      refresh_amount_fields(changeset, :with_price)
    else
      refresh_amount_fields(changeset)
    end
  end
  def put_amount_fields(changeset), do: changeset

  defp refresh_amount_fields(changeset = %Changeset{ changes: %{ source_id: source_id, source_type: "PointTransaction" } }) do
    account_id = get_field(changeset, :account_id)
    point_transaction = source(account_id, source_id, "PointTransaction")
    sub_total_cents = point_transaction.amount

    changeset
    |> put_change(:sub_total_cents, sub_total_cents)
    |> put_change(:tax_one_cents, 0)
    |> put_change(:tax_two_cents, 0)
    |> put_change(:tax_three_cents, 0)
    |> put_change(:grand_total_cents, sub_total_cents)
    |> put_change(:authorization_toal_cents, sub_total_cents)
  end
  defp refresh_amount_fields(changeset = %Changeset{ valid?: true }) do
    sub_total_cents = get_field(changeset, :sub_total_cents)
    tax_one_cents = get_field(changeset, :tax_one_cents)
    tax_two_cents = get_field(changeset, :tax_two_cents)
    tax_three_cents = get_field(changeset, :tax_three_cents)
    grand_total_cents = sub_total_cents + tax_one_cents + tax_two_cents + tax_three_cents

    changeset
    |> put_change(:grand_total_cents, grand_total_cents)
    |> put_change(:authorization_toal_cents, grand_total_cents)
  end
  defp refresh_amount_fields(changeset, :with_price) do
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

    authorization_toal_cents = if is_estimate do
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
    |> put_change(:authorization_toal_cents, authorization_toal_cents)
  end

  def root(query) do
    from oli in query, where: is_nil(oli.parent_id)
  end

  def leaf(query) do
    from oli in query, where: oli.is_leaf == true
  end

  def balance!(struct = %OrderLineItem{ is_leaf: true, parent_id: nil }), do: struct
  def balance!(struct = %OrderLineItem{ is_leaf: true }) do
    parent = assoc(struct, :parent) |> Repo.one()
    balance!(parent)
  end
  def balance!(struct = %OrderLineItem{ product_id: product_id }) when not is_nil(product_id) do
    product = Repo.get!(Product, product_id)
    balance_by_product(struct, product)
  end
  def balance!(struct), do: struct
  def balance_by_product(struct, product = %Product{ kind: kind }) when kind == "simple" or kind == "item" or kind == "variant" do
    source_order_quantity = product.source_quantity * struct.order_quantity
    source = source(product.account_id, product.source_id, product.source_type)

    # Product Variant should ever only have one child
    child = assoc(struct, :children) |> Repo.one()
    child_fields = %{
      account_id: struct.account_id,
      order_id: struct.order_id,
      source_id: product.source_id,
      source_type: product.source_type,
      parent_id: struct.id,
      is_leaf: true,
      name: source.name,
      order_quantity: source_order_quantity,
      charge_quantity: struct.charge_quantity,
      sub_total_cents: struct.sub_total_cents,
      tax_one_cents: struct.tax_one_cents,
      tax_two_cents: struct.tax_two_cents,
      tax_three_cents: struct.tax_three_cents,
      grand_total_cents: struct.grand_total_cents,
      authorization_toal_cents: struct.authorization_toal_cents,
      translations: Translation.merge_translations(%{}, source.translations, ["name"])
    }

    case child do
      nil -> Repo.insert!(Changeset.change(%OrderLineItem{}, child_fields))
      _ ->
        child
        |> Changeset.change(child_fields)
        |> Repo.update!()
    end

    struct
  end
  def balance_by_product(struct, product = %Product{ kind: kind}) when kind == "combo" do
    price = Repo.get!(Price, struct.price_id) |> Repo.preload(:children)
    items = assoc(product, :items) |> Repo.all()

    Enum.each(items, fn(item) ->
      existing_child = Repo.get_by(OrderLineItem, parent_id: struct.id, product_id: item.id)
      child = case existing_child do
        nil -> %OrderLineItem{}
        _ -> existing_child
      end

      target_price = Enum.find(price.children, fn(child_price) ->
        child_price.product_id == item.id
      end)
      changeset = OrderLineItem.changeset(child, %{
        "account_id" => struct.account_id,
        "order_id" => struct.order_id,
        "product_id" => item.id,
        "order_quantity" => struct.order_quantity,
        "parent_id" => struct.id,
        "price_id" => target_price.id
      })

      updated_child = case existing_child do
        nil -> Repo.insert!(changeset)
        _ -> Repo.update!(changeset)
      end

      OrderLineItem.balance!(updated_child)
    end)

    struct
  end

  def query() do
    from(oli in OrderLineItem, order_by: [desc: oli.inserted_at])
  end
  def query(:root) do
    from(oli in OrderLineItem, where: is_nil(oli.parent_id), order_by: [desc: oli.inserted_at])
  end
  def query(:is_leaf) do
    from(oli in OrderLineItem, where: oli.is_leaf == true, order_by: [desc: oli.inserted_at])
  end

  def preload_keyword(:children) do
    [children: query()]
  end

  def preload_keyword(:price) do
    [price: query()]
  end

  def process(line_item = %OrderLineItem{ source_id: source_id, source_type: "Unlockable" }, _, %Changeset{ data: %{ status: "cart" }, changes: %{ status: "opened" } }, customer) when not is_nil(source_id) do
    changeset = Unlock.changeset(%Unlock{}, %{ account_id: line_item.account_id, unlockable_id: source_id, customer_id: customer.id })
    Repo.insert!(changeset)
  end
  def process(line_item = %OrderLineItem{ source_id: source_id, source_type: "Depositable" }, _, %Changeset{ data: %{ status: "cart" }, changes: %{ status: "opened" } }, customer) when not is_nil(source_id) do
    {:ok, %{ data: depositable }} = Goods.do_get_depositable(%AccessRequest{
      vas: %{ account_id: line_item.account_id },
      params: %{ "id" => source_id }
    })

    if depositable.target_type == "PointAccount" do
      {:ok, _} = CRM.do_create_point_transaction(%AccessRequest{
        vas: %{ account_id: line_item.account_id },
        fields: %{
          "status" => "committed",
          "customer_id" => customer.id,
          "amount" => line_item.order_quantity * depositable.amount,
          "reason_label" => "self_deposit",
          "source_id" => line_item.id,
          "source_type" => "OrderLineItem"
        }
      })
    else
      line_item
    end
  end
  def process(line_item = %OrderLineItem{ source_id: source_id, source_type: "PointTransaction" }, _, %Changeset{ data: %{ status: "cart" }, changes: %{ status: "opened" } }, _) when not is_nil(source_id) do
    {:ok, %{ data: _ }} = CRM.do_update_point_transaction(%AccessRequest{
      vas: %{ account_id: line_item.account_id },
      params: %{ "id" => source_id },
      fields: %{
        "status" => "committed"
      }
    })
  end
  def process(line_item, _, _, _) do
    {:ok, line_item}
  end
  def process(line_item, :delete) do
    {:ok, line_item}
  end

  defmodule Query do
    use BlueJet, :query

    def preloads(:order) do
      [order: Order]
    end
    def preloads({:order, order_preloads}) do
      [order: {Order.Query.default(), Order.Query.preloads(order_preloads)}]
    end
    def preloads(:children) do
      [children: OrderLineItem.Query.default()]
    end

    def for_account(query, account_id) do
      from(oli in query, where: oli.account_id == ^account_id)
    end

    def root() do
      from(oli in OrderLineItem, where: is_nil(oli.parent_id), order_by: [desc: oli.inserted_at])
    end

    def default() do
      from(oli in OrderLineItem, order_by: [desc: oli.inserted_at])
    end

    def with_order(query, filter) do
      from(
        oli in query,
        join: o in Order, where: oli.order_id == o.id,
        where: o.fulfillment_status == ^filter[:fulfillment_status],
        where: o.customer_id == ^filter[:customer_id]
      )
    end
  end
end
