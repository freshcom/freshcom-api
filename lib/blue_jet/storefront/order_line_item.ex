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

  import BlueJet.Identity.Shortcut
  import BlueJet.Catalogue.Shortcut
  import BlueJet.Goods.Shortcut

  alias Decimal, as: D
  alias Ecto.Changeset

  alias BlueJet.AccessRequest
  alias BlueJet.Translation

  alias BlueJet.Goods
  alias BlueJet.CRM
  alias BlueJet.Distribution

  alias BlueJet.Catalogue.Product
  alias BlueJet.Catalogue.Price

  alias BlueJet.Storefront.OrderLineItem
  alias BlueJet.Storefront.Order
  alias BlueJet.Storefront.Unlock

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

    field :source_id, Ecto.UUID
    field :source_type, :string

    timestamps()

    belongs_to :order, Order
    belongs_to :price, Price
    belongs_to :product, Product
    belongs_to :parent, __MODULE__
    has_many :children, __MODULE__, foreign_key: :parent_id, on_delete: :delete_all
  end

  @doc """
  Returns a list of fields that is managed by the system.
  """
  def system_fields do
    [
      :id,
      :account_id,
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

  @doc """
  Returns a list of fields that is changable by user input.
  """
  def writable_fields do
    __MODULE__.__schema__(:fields) -- system_fields()
  end

  @doc """
  Returns a list of fields that can be changed for the given order line item.
  """
  def castable_fields(%{ __meta__: %{ state: :built }}), do: writable_fields()
  def castable_fields(%{ __meta__: %{ state: :loaded }}), do: writable_fields() -- [:order_id, :product_id, :parent_id]

  @doc """
  Returns a list of fields that can be translated.
  """
  def translatable_fields do
    __MODULE__.__trans__(:fields)
  end

  @doc """
  Returns the required fields for the given `changeset`.
  """
  def required_fields(changeset), do: required_fields(changeset.data, changeset.changes)
  defp required_fields, do: [:account_id, :order_id, :order_quantity]
  defp required_fields(%{ __meta__: %{ state: :built } }, %{ product_id: _ }), do: required_fields()
  defp required_fields(%{ __meta__: %{ state: :built } }, %{ source_type: "PointTransaction" }), do: required_fields()
  defp required_fields(%{ __meta__: %{ state: :built } }, _), do: required_fields() ++ [:sub_total_cents]
  defp required_fields(%{ __meta__: %{ state: :loaded } }, _), do: []

  @doc """
  Returns the source of the given product.
  """
  def get_source(product, locale \\ nil)

  def get_source(oli = %{ source_id: source_id, source_type: "PointTransaction" }, locale) do
    account = get_account(oli)
    response = CRM.do_get_point_transaction(%AccessRequest{
      account: account,
      params: %{ "id" => source_id },
      locale: locale || account.default_locale
    })

    case response do
      {:ok, %{ data: point_transaction }} -> point_transaction
      {:error, _} -> nil
    end
  end

  def get_source(oli = %{ source_id: source_id, source_type: source_type }, locale) do
    get_goods(%{ id: source_id, type: source_type }, oli, locale)
  end

  def get_source(_, _), do: nil

  @doc """
  Returns the validated changeset.
  """
  def validate(changeset) do
    required_fields = required_fields(changeset)

    changeset
    |> validate_required(required_fields)
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
  def changeset(struct, params, locale \\ nil, default_locale \\ nil) do
    default_locale = default_locale || get_default_locale(struct)
    locale = locale || default_locale

    struct
    |> cast(params, castable_fields(struct))
    |> validate()
    |> put_is_leaf()
    |> put_name()
    |> put_print_name()
    |> put_price_id()
    |> put_price_fields()
    |> put_is_estimate()
    |> put_charge_quantity()
    |> put_amount_fields()
    |> put_auto_fulfill()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  #######
  defp put_auto_fulfill(changeset = %{ changes: %{ auto_fulfill: _ } }), do: changeset

  defp put_auto_fulfill(changeset = %{ valid?: true, changes: %{ product_id: product_id } }) do
    account = get_account(changeset.data)
    product = get_product(%{ product_id: product_id, product: nil, account: account })

    put_change(changeset, :auto_fulfill, product.auto_fulfill)
  end

  defp put_auto_fulfill(changeset = %{ data: %{ auto_fulfill: nil }, valid?: true }) do
    grand_total_cents = get_field(changeset, :grand_total_cents)

    if grand_total_cents >= 0 do
      put_change(changeset, :auto_fulfill, false)
    else
      put_change(changeset, :auto_fulfill, true)
    end
  end

  defp put_auto_fulfill(changeset), do: changeset

  #######
  defp put_print_name(changeset = %{ changes: %{ print_name: _ } }), do: changeset

  defp put_print_name(changeset = %{ data: %{ print_name: nil }, valid?: true }) do
    put_change(changeset, :print_name, get_field(changeset, :name))
  end

  defp put_print_name(changeset), do: changeset

  #######
  defp put_is_leaf(changeset = %Changeset{ valid?: true, changes: %{ product_id: _ } }) do
    put_change(changeset, :is_leaf, false)
  end

  defp put_is_leaf(changeset), do: changeset

  #######
  defp put_name(changeset = %Changeset{ valid?: true, changes: %{ name: _ } }) do
    changeset
  end

  defp put_name(changeset = %Changeset{ valid?: true, changes: %{ product_id: product_id }}) do
    product = Repo.get!(Product, product_id)
    translations =
      get_field(changeset, :translations)
      |> Translation.merge_translations(product.translations, ["name"])

    changeset
    |> put_change(:name, product.name)
    |> put_change(:translations, translations)
  end

  defp put_name(changeset), do: changeset

  #######
  defp put_is_estimate(changeset = %Changeset{ valid?: true, changes: %{ is_estimate: _ } }) do
    changeset
  end

  defp put_is_estimate(changeset = %Changeset{ valid?: true, data: %{ id: nil } }) do
    price_estimate_by_default = get_field(changeset, :price_estimate_by_default)
    charge_quantity = get_field(changeset, :charge_quantity)
    cond do
      price_estimate_by_default && !charge_quantity -> put_change(changeset, :is_estimate, true)
      true -> put_change(changeset, :is_estimate, false)
    end
  end

  defp put_is_estimate(changeset), do: changeset

  #######
  defp put_price_id(changeset = %Changeset{ valid?: true, changes: %{ price_id: _ } }), do: changeset

  defp put_price_id(changeset = %Changeset{ valid?: true, changes: %{ product_id: product_id }}) do
    order_quantity = get_field(changeset, :order_quantity)
    price = Price.query_for(product_id: product_id, order_quantity: order_quantity) |> Repo.one()
    put_change(changeset, :price_id, price.id)
  end

  defp put_price_id(changeset), do: changeset

  #######
  defp put_price_fields(changeset = %Changeset{ valid?: true, changes: %{ price_id: price_id } }) do
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

  defp put_price_fields(changeset), do: changeset

  #######
  defp put_charge_quantity(changeset = %Changeset{ valid?: true, changes: %{ charge_quantity: _ } }) do
    changeset
  end

  defp put_charge_quantity(changeset = %Changeset{ valid?: true, changes: %{ sub_total_cents: sub_total_cents } }) when not is_nil(sub_total_cents) do
    price_charge_amount_cents = get_field(changeset, :price_charge_amount_cents)

    if price_charge_amount_cents do
      charge_quantity = D.div(D.new(sub_total_cents), D.new(price_charge_amount_cents))
      put_change(changeset, :charge_quantity, charge_quantity)
    else
      put_change(changeset, :charge_quantity, D.new(get_field(changeset, :order_quantity)))
    end
  end

  defp put_charge_quantity(changeset = %Changeset{ valid?: true }) do
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

  defp put_charge_quantity(changeset), do: changeset

  #######
  defp put_amount_fields(changeset = %Changeset{ valid?: true }) do
    if get_field(changeset, :price_id) do
      refresh_amount_fields(changeset, :with_price)
    else
      refresh_amount_fields(changeset)
    end
  end

  defp put_amount_fields(changeset), do: changeset

  #######
  defp refresh_amount_fields(changeset = %Changeset{ changes: %{ source_id: source_id, source_type: "PointTransaction" } }) do
    account_id = get_field(changeset, :account_id)
    point_transaction = get_source(%{
      source_id: source_id,
      source_type: "PointTransaction",
      account_id: account_id,
      account: nil
    })
    sub_total_cents = point_transaction.amount

    changeset
    |> put_change(:sub_total_cents, sub_total_cents)
    |> put_change(:tax_one_cents, 0)
    |> put_change(:tax_two_cents, 0)
    |> put_change(:tax_three_cents, 0)
    |> put_change(:grand_total_cents, sub_total_cents)
    |> put_change(:authorization_total_cents, sub_total_cents)
  end

  defp refresh_amount_fields(changeset = %Changeset{ valid?: true }) do
    sub_total_cents = get_field(changeset, :sub_total_cents)
    tax_one_cents = get_field(changeset, :tax_one_cents)
    tax_two_cents = get_field(changeset, :tax_two_cents)
    tax_three_cents = get_field(changeset, :tax_three_cents)
    grand_total_cents = sub_total_cents + tax_one_cents + tax_two_cents + tax_three_cents

    changeset
    |> put_change(:grand_total_cents, grand_total_cents)
    |> put_change(:authorization_total_cents, grand_total_cents)
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

  @doc """
  Balance the order line item by creating or updating its children.

  If the order line item has parent, then calling this function has the same
  effect as if it is called on the parent. This function will search for the
  root and balance towards the leaf.

  This function will balance the entire branch regardless which order line item
  on the branch is the input.

  Returns the input order line item after its being balanced.
  """
  def balance!(struct = %__MODULE__{ is_leaf: true, parent_id: nil }), do: struct

  def balance!(struct = %__MODULE__{ is_leaf: true }) do
    parent = assoc(struct, :parent) |> Repo.one()
    balance!(parent)
  end

  def balance!(struct = %__MODULE__{ product_id: product_id }) when not is_nil(product_id) do
    product = Repo.get!(Product, product_id)
    balance_by_product(struct, product)
  end

  def balance!(struct), do: struct

  ######
  defp balance_by_product(struct, product = %Product{ kind: kind }) when kind in ["simple", "item", "variant"] do
    source_order_quantity = product.source_quantity * struct.order_quantity
    source_charge_quantity = if struct.price_estimate_by_default do
      struct.charge_quantity
    else
      D.new(source_order_quantity)
    end
    source = get_source(product)

    # Product variant should ever only have one child
    child = assoc(struct, :children) |> Repo.one()
    child_fields = %{
      account_id: struct.account_id,
      order_id: struct.order_id,
      source_id: product.source_id,
      source_type: product.source_type,
      parent_id: struct.id,
      is_leaf: true,
      auto_fulfill: struct.auto_fulfill,
      name: source.name,
      order_quantity: source_order_quantity,
      charge_quantity: source_charge_quantity,
      sub_total_cents: struct.sub_total_cents,
      tax_one_cents: struct.tax_one_cents,
      tax_two_cents: struct.tax_two_cents,
      tax_three_cents: struct.tax_three_cents,
      grand_total_cents: struct.grand_total_cents,
      authorization_total_cents: struct.authorization_total_cents,
      translations: Translation.merge_translations(%{}, source.translations, ["name"])
    }

    case child do
      nil -> Repo.insert!(Changeset.change(%__MODULE__{}, child_fields))

      _ ->
        child
        |> Changeset.change(child_fields)
        |> Repo.update!()
    end

    struct
  end

  defp balance_by_product(struct, product = %Product{ kind: kind }) when kind == "combo" do
    price = Repo.get!(Price, struct.price_id) |> Repo.preload(:children)
    items = assoc(product, :items) |> Repo.all()

    Enum.each(items, fn(item) ->
      existing_child = Repo.get_by(__MODULE__, parent_id: struct.id, product_id: item.id)
      child = case existing_child do
        nil -> %__MODULE__{ account_id: struct.account_id }

        _ -> existing_child
      end

      target_price = Enum.find(price.children, fn(child_price) ->
        child_price.product_id == item.id
      end)
      changeset = __MODULE__.changeset(child, %{
        "auto_fulfill" => struct.auto_fulfill,
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

      __MODULE__.balance!(updated_child)
    end)

    struct
  end

  @doc """
  Process the given order line item so that other related resource can be created/updated.

  This function may change the order line item in database.

  External resources maybe created/updated.

  Returns the processed order line item.
  """
  def process(line_item = %__MODULE__{ source_id: source_id, source_type: "Unlockable" }, _, %Changeset{ data: %{ status: "cart" }, changes: %{ status: "opened" } }, customer) when not is_nil(source_id) do
    %Unlock{ account_id: line_item.account_id }
    |> Changeset.change(%{
        unlockable_id: source_id,
        customer_id: customer.id,
        source_id: line_item.id,
        source_type: "OrderLineItem"
       })
    |> Repo.insert!()
  end

  def process(line_item = %__MODULE__{ source_id: source_id, source_type: "Depositable" }, _, %Changeset{ data: %{ status: "cart" }, changes: %{ status: "opened" } }, customer) when not is_nil(source_id) do
    account = get_account(line_item)
    {:ok, %{ data: depositable }} = Goods.do_get_depositable(%AccessRequest{
      account: account,
      params: %{ "id" => source_id }
    })

    if depositable.target_type == "PointAccount" do
      {:ok, _} = CRM.do_create_point_transaction(%AccessRequest{
        account: account,
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

  def process(line_item = %__MODULE__{ source_id: source_id, source_type: "PointTransaction" }, _, %Changeset{ data: %{ status: "cart" }, changes: %{ status: "opened" } }, _) when not is_nil(source_id) do
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

  @doc """
  Returns the order line item with fulfillment status updated.
  """
  def refresh_fulfillment_status(oli) do
    oli
    |> Changeset.change(fulfillment_status: get_fulfillment_status(oli))
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
  Returns the order line item base on the fulfillment of the given order line item.

  It will always return the corrent fulfillment status where as the `fulfillment_status`
  field of the order line item may not be up to date yet.
  """
  def get_fulfillment_status(%{ grant_total_cents: grand_total_cents }) when grand_total_cents < 0 do
    "fulfilled"
  end

  def get_fulfillment_status(oli = %{ is_leaf: true }) do
    account = get_account(oli)
    {:ok, %{ data: flis }} = Distribution.do_list_fulfillment_line_item(%AccessRequest{
      account: account,
      filter: %{ source_id: oli.id, source_type: "OrderLineItem" },
      pagination: %{ size: 1000, number: 1 }
    })

    fulfillable_quantity = oli.order_quantity
    fulfilled_quantity =
      flis
      |> Enum.filter(fn(fli) -> fli.status == "fulfilled" end)
      |> Enum.map(fn(fli) -> fli.quantity end)
      |> Enum.sum()

    returned_quantity =
      flis
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

  defmodule Query do
    use BlueJet, :query

    def default() do
      from(oli in OrderLineItem, order_by: [desc: oli.inserted_at])
    end

    def for_order(query, order_id) do
      from oli in query, where: oli.order_id == ^order_id
    end

    def with_auto_fulfill(query) do
      from oli in query, where: oli.auto_fulfill == true
    end

    def with_positive_amount(query) do
      from oli in query, where: oli.grand_total_cents >= 0
    end

    def id_only(query) do
      from oli in query, select: oli.id
    end

    def fulfillable(query) do
      query
      |> leaf()
      |> with_positive_amount()
    end

    def preloads({:order, order_preloads}, options) do
      [order: {Order.Query.default(), Order.Query.preloads(order_preloads, options)}]
    end

    def preloads({:children, children_preloads}, options) do
      [children: {OrderLineItem.Query.default(), OrderLineItem.Query.preloads(children_preloads, options)}]
    end

    def for_account(query, account_id) do
      from(oli in query, where: oli.account_id == ^account_id)
    end

    def root() do
      from(oli in OrderLineItem, where: is_nil(oli.parent_id), order_by: [desc: oli.inserted_at])
    end

    def root(query) do
      from(oli in query, where: is_nil(oli.parent_id), order_by: [desc: oli.inserted_at])
    end

    def leaf(query) do
      from oli in query, where: oli.is_leaf == true
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
