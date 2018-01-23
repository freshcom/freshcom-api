defmodule BlueJet.Catalogue.Price do
  use BlueJet, :data

  use Trans, translates: [
    :name,
    :order_unit,
    :charge_unit,
    :caption,
    :description,
    :custom_data
  ], container: :translations

  alias Decimal, as: D
  alias Ecto.Changeset

  alias BlueJet.Repo
  alias BlueJet.Translation
  alias BlueJet.Catalogue.Product

  schema "prices" do
    field :account_id, Ecto.UUID
    field :status, :string, default: "draft"
    field :code, :string
    field :name, :string
    field :label, :string

    field :currency_code, :string, default: "CAD"
    field :charge_amount_cents, :integer
    field :charge_unit, :string
    field :order_unit, :string

    field :estimate_by_default, :boolean, default: false
    field :estimate_average_percentage, :decimal
    field :estimate_maximum_percentage, :decimal
    field :minimum_order_quantity, :integer, default: 1

    field :tax_one_percentage, :decimal, default: Decimal.new(0)
    field :tax_two_percentage, :decimal, default: Decimal.new(0)
    field :tax_three_percentage, :decimal, default: Decimal.new(0)

    field :start_time, :utc_datetime
    field :end_time, :utc_datetime

    field :caption, :string
    field :description, :string
    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    timestamps()

    belongs_to :product, Product
    belongs_to :parent, __MODULE__
    has_many :children, __MODULE__, foreign_key: :parent_id, on_delete: :delete_all
  end

  @type t :: Ecto.Schema.t

  @system_fields [
    :id,
    :account_id,
    :inserted_at,
    :updated_at
  ]

  def writable_fields do
    __MODULE__.__schema__(:fields) -- @system_fields
  end

  def translatable_fields do
    __MODULE__.__trans__(:fields)
  end

  defp required_fields(changeset) do
    common_required = [:name, :product_id, :status, :currency_code, :charge_amount_cents, :charge_unit]
    case get_field(changeset, :estimate_by_default) do
      true -> common_required ++ [:order_unit, :estimate_average_percentage, :estimate_maximum_percentage]
      _ -> common_required
    end
  end

  def validate_status(changeset = %Changeset{ changes: %{ status: "active" } }) do
    moq = get_field(changeset, :minimum_order_quantity)
    product_id = get_field(changeset, :product_id)

    price = Repo.get_by(__MODULE__, product_id: product_id, minimum_order_quantity: moq, status: "active")

    case price do
      nil -> changeset
      _ -> Changeset.add_error(changeset, :status, "There is already an active price with the same minimum order quantity.", [validation: :minimum_order_quantity_taken, full_error_message: true])
    end
  end
  def validate_status(changeset = %Changeset{ changes: %{ status: _ } }) do
    product_id = get_field(changeset, :product_id)
    product = Repo.get_by(Product, id: product_id)

    validate_status(changeset, product.status)
  end
  def validate_status(changeset), do: changeset
  defp validate_status(changeset = %Changeset{ changes: %{ status: _ } }, "active") do
    price_id = get_field(changeset, :id)
    product_id = get_field(changeset, :product_id)

    other_active_prices = cond do
      price_id && product_id -> from(p in __MODULE__, where: p.product_id == ^product_id, where: p.id != ^price_id, where: p.status == "active")
      !price_id && product_id -> from(p in __MODULE__, where: p.product_id == ^product_id, where: p.status == "active")
    end
    oap_count = Repo.aggregate(other_active_prices, :count, :id)

    case oap_count do
      0 -> Changeset.add_error(changeset, :status, "Can not change status of the only Active Price of a Active Product.", [validation: :active_product_depends_on_active_price, full_error_message: true])
      _ -> changeset
    end
  end
  defp validate_status(changeset = %Changeset{ changes: %{ status: "internal" } }, "internal"), do: changeset
  defp validate_status(changeset = %Changeset{ changes: %{ status: _ } }, "internal") do
    price_id = get_field(changeset, :id)
    product_id = get_field(changeset, :product_id)

    other_active_or_internal_prices = from(p in __MODULE__, where: p.product_id == ^product_id, where: p.id != ^price_id, where: p.status in ["active", "internal"])
    oaip_count = Repo.aggregate(other_active_or_internal_prices, :count, :id)

    case oaip_count do
      0 -> Changeset.add_error(changeset, :status, "Can not change status of the only Active/Internal Price of a Internal Product.", [validation: :internal_product_depends_on_internal_price, full_error_message: true])
      _ -> changeset
    end
  end
  defp validate_status(changeset, _), do: changeset

  def validate(changeset) do
    changeset
    |> validate_required(required_fields(changeset))
    |> validate_assoc_account_scope(:product)
    |> validate_status()
  end

  defp castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields()
  end

  defp castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:product_id]
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params, locale \\ nil, default_locale \\ nil) do
    struct
    |> cast(params, castable_fields(struct))
    |> put_status()
    |> put_label()
    |> put_charge_unit()
    |> put_order_unit()
    |> put_minimum_order_quantity()
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  def put_status(changeset = %{ changes: %{ parent_id: parent_id } }) do
    parent = Repo.get(__MODULE__, parent_id)
    put_change(changeset, :status, parent.status)
  end

  def put_status(changeset), do: changeset

  def put_label(changeset = %{ changes: %{ parent_id: parent_id } }) do
    parent = Repo.get(__MODULE__, parent_id)
    put_change(changeset, :label, parent.label)
  end

  def put_label(changeset), do: changeset

  def put_charge_unit(changeset = %{ changes: %{ parent_id: parent_id } }) do
    parent = Repo.get(__MODULE__, parent_id)
    changeset = put_change(changeset, :charge_unit, parent.charge_unit)

    new_translations =
      changeset
      |> Changeset.get_field(:translations)
      |> Translation.merge_translations(parent.translations, ["charge_unit"])

    put_change(changeset, :translations, new_translations)
  end

  def put_charge_unit(changeset), do: changeset

  def put_minimum_order_quantity(changeset = %{ changes: %{ parent_id: parent_id } }) do
    parent = Repo.get(__MODULE__, parent_id)
    put_change(changeset, :minimum_order_quantity, parent.minimum_order_quantity)
  end

  def put_minimum_order_quantity(changeset), do: changeset

  def put_order_unit(changeset = %{ changes: %{ charge_unit: charge_unit } }) do
    case get_field(changeset, :estimate_by_default) do
      false -> put_change(changeset, :order_unit, charge_unit)
      _ -> changeset
    end
  end

  def put_order_unit(changeset = %{ changes: %{ estimate_by_default: false } }) do
    charge_unit = get_field(changeset, :charge_unit)
    put_change(changeset, :order_unit, charge_unit)
  end

  def put_order_unit(changeset), do: changeset

  def get_estimate_average_rate(%{ estimate_average_percentage: nil }), do: nil
  def get_estimate_average_rate(%{ estimate_average_percentage: p }) do
    D.new(p) |> D.div(D.new(100))
  end

  def get_estimate_average_rate(%{ estimate_maximum_percentage: nil }), do: nil
  def get_estimate_average_rate(%{ estimate_maximum_percentage: p }) do
    D.new(p) |> D.div(D.new(100))
  end

  # TODO: Refactor this
  def query_for(product_item_id: product_item_id, order_quantity: order_quantity) do
    query = from p in __MODULE__,
      where: p.status == "active",
      where: p.product_item_id == ^product_item_id,
      where: p.minimum_order_quantity <= ^order_quantity,
      order_by: [desc: p.minimum_order_quantity]

    query |> first()
  end
  def query_for(product_id: product_id, order_quantity: order_quantity) do
    query = from p in __MODULE__,
      where: p.status == "active",
      where: p.product_id == ^product_id,
      where: p.minimum_order_quantity <= ^order_quantity,
      order_by: [desc: p.minimum_order_quantity]

    query |> first()
  end
  def query_for(product_item_ids: product_item_ids, order_quantity: order_quantity) do
    query = from p in __MODULE__,
      select: %{ row_number: fragment("ROW_NUMBER() OVER (PARTITION BY product_item_id ORDER BY minimum_order_quantity DESC)"), id: p.id },
      where: p.status == "active",
      where: p.product_item_id in ^product_item_ids,
      where: p.minimum_order_quantity <= ^order_quantity

    query = from pp in subquery(query),
      join: p in ^__MODULE__, on: pp.id == p.id,
      where: pp.row_number == 1,
      select: p

    query
  end

  def balance(price) do
    children = Ecto.assoc(price, :children) |> Repo.all()
    charge_amount_cents = Enum.reduce(children, 0, fn(child, acc) ->
      acc + child.charge_amount_cents
    end)

    changeset = __MODULE__.changeset(price, %{ "charge_amount_cents" => charge_amount_cents })
    Repo.update!(changeset)
  end

  defmodule Query do
    use BlueJet, :query

    alias BlueJet.Catalogue.Price

    def default() do
      from(p in Price, order_by: [desc: :inserted_at])
    end

    def for_product(product_id) do
      from(p in Price, where: p.product_id == ^product_id, order_by: [asc: :minimum_order_quantity])
    end

    def with_order_quantity(query, order_quantity) do
      from(p in query, where: p.minimum_order_quantity <= ^order_quantity)
    end

    def with_status(query, status) do
      from p in query, where: p.status == ^status
    end

    def active_by_moq() do
      from(p in Price, where: p.status == "active", order_by: [asc: :minimum_order_quantity])
    end

    def for_account(query, account_id) do
      from(p in query, where: p.account_id == ^account_id)
    end

    def active(query) do
      from(p in query, where: p.status == "active")
    end

    def preloads({:product, product_preloads}, options) do
      query = Product.Query.default()
      [product: {query, Product.Query.preloads(product_preloads, options)}]
    end

    def preloads({:children, children_preloads}, options) do
      query = Price.Query.default()
      [children: {query, Price.Query.preloads(children_preloads, options)}]
    end

    def preloads(_, _) do
      []
    end

  end
end
