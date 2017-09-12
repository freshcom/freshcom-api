defmodule BlueJet.Storefront.Price do
  use BlueJet, :data

  use Trans, translates: [:name, :caption], container: :translations

  alias Ecto.Changeset

  alias BlueJet.Repo
  alias BlueJet.Translation
  alias BlueJet.Storefront.Price
  alias BlueJet.Storefront.ProductItem
  alias BlueJet.Identity.Account

  schema "prices" do
    field :status, :string
    field :name, :string
    field :label, :string
    field :caption, :string
    field :currency_code, :string, default: "CAD"
    field :charge_cents, Money.Ecto.Type
    field :estimate_average_percentage, :decimal
    field :estimate_maximum_percentage, :decimal
    field :minimum_order_quantity, :integer, default: 1
    field :order_unit, :string
    field :charge_unit, :string
    field :estimate_by_default, :boolean, default: false
    field :tax_one_percentage, :decimal, default: Decimal.new(0)
    field :tax_two_percentage, :decimal, default: Decimal.new(0)
    field :tax_three_percentage, :decimal, default: Decimal.new(0)
    field :start_time, :utc_datetime
    field :end_time, :utc_datetime

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    timestamps()

    belongs_to :account, Account
    belongs_to :product_item, ProductItem
  end

  def system_fields do
    [
      :id,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    Price.__schema__(:fields) -- system_fields()
  end

  def translatable_fields do
    Price.__trans__(:fields)
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:account_id]
  end

  def required_fields(changeset) do
    common_required = [:account_id, :status, :label, :currency_code, :charge_cents, :charge_unit]
    case get_field(changeset, :estimate_by_default) do
      true -> common_required ++ [:order_unit, :estimate_average_percentage, :estimate_maximum_percentage]
      _ -> common_required
    end
  end

  def validate(changeset) do
    changeset
    |> validate_required(required_fields(changeset))
    |> foreign_key_constraint(:account_id)
    |> validate_assoc_account_scope(:product_item)
    |> validate_status()
  end

  def validate_status(changeset = %Changeset{ changes: %{ status: "active" } }) do
    moq = get_field(changeset, :minimum_order_quantity)
    product_item_id = get_field(changeset, :product_item_id)
    price = Repo.get_by(Price, product_item_id: product_item_id, minimum_order_quantity: moq, status: "active")

    case price do
      nil -> changeset
      _ -> Changeset.add_error(changeset, :status, "There is already an Active Price that have the same Minimum Order Quantity.", [validation: :can_only_active_one_per_moq, full_error_message: true])
    end
  end
  def validate_status(changeset = %Changeset{ changes: %{ status: _ } }) do
    product_item_id = get_field(changeset, :product_item_id)
    product_item = Repo.get_by(ProductItem, id: product_item_id)

    validate_status(changeset, product_item)
  end
  def validate_status(changeset), do: changeset
  defp validate_status(changeset = %Changeset{ changes: %{ status: _ } } , product_item = %ProductItem{ status: "active" }) do
    price_id = get_field(changeset, :id)

    prices = Ecto.assoc(product_item, :prices)
    other_active_prices = if price_id do
      from(p in prices, where: p.id != ^price_id, where: p.status == "active")
    else
      from(p in prices, where: p.status == "active")
    end
    oap_count = Repo.aggregate(other_active_prices, :count, :id)

    case oap_count do
      0 -> Changeset.add_error(changeset, :status, "Can not change status of the only Active Price of a Active Product Item.", [validation: "cannot_change_status_of_only_active_price_of_active_product_item", full_error_message: true])
      _ -> changeset
    end
  end
  defp validate_status(changeset = %Changeset{ changes: %{ status: "internal" } }, product_item = %ProductItem{ status: "internal" }), do: changeset
  defp validate_status(changeset = %Changeset{ changes: %{ status: _ } }, product_item = %ProductItem{ status: "internal" }) do
    price_id = get_field(changeset, :id)

    prices = Ecto.assoc(product_item, :prices)
    other_active_or_internal_prices = from(p in prices, where: p.id != ^price_id, where: p.status in ["active", "internal"])
    oaip_count = Repo.aggregate(other_active_or_internal_prices, :count, :id)

    case oaip_count do
      0 -> Changeset.add_error(changeset, :status, "Can not change status of the only Active Price of a Active Product Item.", [validation: "cannot_change_status_of_only_internal_price_of_internal_product_item", full_error_message: true])
      _ -> changeset
    end
  end
  defp validate_status(changeset, _), do: changeset

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}, locale \\ "en") do
    struct
    |> cast(params, castable_fields(struct))
    |> validate()
    |> put_order_unit()
    |> Translation.put_change(translatable_fields(), locale)
  end

  def put_order_unit(changeset = %Changeset{ valid?: true, changes: %{ charge_unit: charge_unit } }) do
    case get_field(changeset, :estimate_by_default) do
      false -> put_change(changeset, :order_unit, charge_unit)
      _ -> changeset
    end
  end
  def put_order_unit(changeset = %Changeset{ valid?: true, changes: %{ estimate_by_default: false } }) do
    charge_unit = get_field(changeset, :charge_unit)
    put_change(changeset, :order_unit, charge_unit)
  end
  def put_order_unit(changeset), do: changeset

  def query_for(product_item_id: product_item_id, order_quantity: order_quantity) do
    query = from p in Price,
      where: p.status == "active",
      where: p.product_item_id == ^product_item_id,
      where: p.minimum_order_quantity <= ^order_quantity,
      order_by: [desc: p.minimum_order_quantity]

    query |> first()
  end
  def query_for(product_item_ids: product_item_ids, order_quantity: order_quantity) do
    query = from p in Price,
      select: %{ row_number: fragment("ROW_NUMBER() OVER (PARTITION BY product_item_id ORDER BY minimum_order_quantity DESC)"), id: p.id },
      where: p.status == "active",
      where: p.product_item_id in ^product_item_ids,
      where: p.minimum_order_quantity <= ^order_quantity

    query = from pp in subquery(query),
      join: p in Price, on: pp.id == p.id,
      where: pp.row_number == 1,
      select: p

    query
  end

  def query() do
    from(p in Price, order_by: [asc: p.minimum_order_quantity, desc: p.inserted_at])
  end
end
