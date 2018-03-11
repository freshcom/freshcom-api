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
  alias BlueJet.Catalogue.Product
  alias __MODULE__.Proxy

  schema "prices" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

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

  #
  # MARK: Validation
  #
  defp required_fields(changeset) do
    common_required = [:name, :product_id, :status, :currency_code, :charge_amount_cents, :charge_unit]
    case get_field(changeset, :estimate_by_default) do
      true -> common_required ++ [:order_unit, :estimate_average_percentage, :estimate_maximum_percentage]
      _ -> common_required
    end
  end

  def validate_status(changeset = %{ changes: %{ status: "active" } }) do
    moq = get_field(changeset, :minimum_order_quantity)
    product_id = get_field(changeset, :product_id)

    price = Repo.get_by(__MODULE__, product_id: product_id, minimum_order_quantity: moq, status: "active")

    case price do
      nil -> changeset
      _ -> add_error(changeset, :status, "There is already an active price with the same minimum order quantity.", [validation: :minimum_order_quantity_taken, full_error_message: true])
    end
  end
  def validate_status(changeset = %{ changes: %{ status: _ } }) do
    product_id = get_field(changeset, :product_id)
    product = Repo.get_by(Product, id: product_id)

    validate_status(changeset, product.status)
  end
  def validate_status(changeset), do: changeset
  defp validate_status(changeset = %{ changes: %{ status: _ } }, "active") do
    price_id = get_field(changeset, :id)
    product_id = get_field(changeset, :product_id)

    other_active_prices = cond do
      price_id && product_id -> from(p in __MODULE__, where: p.product_id == ^product_id, where: p.id != ^price_id, where: p.status == "active")
      !price_id && product_id -> from(p in __MODULE__, where: p.product_id == ^product_id, where: p.status == "active")
    end
    oap_count = Repo.aggregate(other_active_prices, :count, :id)

    case oap_count do
      0 -> add_error(changeset, :status, "Can not change status of the only Active Price of a Active Product.", [validation: :active_product_depends_on_active_price, full_error_message: true])
      _ -> changeset
    end
  end
  defp validate_status(changeset = %{ changes: %{ status: "internal" } }, "internal"), do: changeset
  defp validate_status(changeset = %{ changes: %{ status: _ } }, "internal") do
    price_id = get_field(changeset, :id)
    product_id = get_field(changeset, :product_id)

    other_active_or_internal_prices = from(p in __MODULE__, where: p.product_id == ^product_id, where: p.id != ^price_id, where: p.status in ["active", "internal"])
    oaip_count = Repo.aggregate(other_active_or_internal_prices, :count, :id)

    case oaip_count do
      0 -> add_error(changeset, :status, "Can not change status of the only Active/Internal Price of a Internal Product.", [validation: :internal_product_depends_on_internal_price, full_error_message: true])
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

  def validate(changeset = %{ data: price }, :delete) do
    if price.status != "disabled" do
      add_error(changeset, :status, {"must be disabled", [validation: :must_be_disabled]})
    else
      changeset
    end
  end

  #
  # MARK: Changeset
  #
  defp castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields()
  end

  defp castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:product_id]
  end

  defp put_status(changeset = %{ changes: %{ parent_id: parent_id } }) do
    parent = Repo.get(__MODULE__, parent_id)
    put_change(changeset, :status, parent.status)
  end

  defp put_status(changeset), do: changeset

  defp put_label(changeset = %{ changes: %{ parent_id: parent_id } }) do
    parent = Repo.get(__MODULE__, parent_id)
    put_change(changeset, :label, parent.label)
  end

  defp put_label(changeset), do: changeset

  defp put_charge_unit(changeset = %{ changes: %{ parent_id: parent_id } }) do
    parent = Repo.get(__MODULE__, parent_id)
    changeset = put_change(changeset, :charge_unit, parent.charge_unit)

    new_translations =
      changeset
      |> get_field(:translations)
      |> Translation.merge_translations(parent.translations, ["charge_unit"])

    put_change(changeset, :translations, new_translations)
  end

  defp put_charge_unit(changeset), do: changeset

  defp put_minimum_order_quantity(changeset = %{ changes: %{ parent_id: parent_id } }) do
    parent = Repo.get(__MODULE__, parent_id)
    put_change(changeset, :minimum_order_quantity, parent.minimum_order_quantity)
  end

  defp put_minimum_order_quantity(changeset), do: changeset

  defp put_order_unit(changeset = %{ changes: %{ charge_unit: charge_unit } }) do
    case get_field(changeset, :estimate_by_default) do
      false -> put_change(changeset, :order_unit, charge_unit)
      _ -> changeset
    end
  end

  defp put_order_unit(changeset = %{ changes: %{ estimate_by_default: false } }) do
    charge_unit = get_field(changeset, :charge_unit)
    put_change(changeset, :order_unit, charge_unit)
  end

  defp put_order_unit(changeset), do: changeset

  def changeset(price, :insert, params) do
    price
    |> cast(params, castable_fields(price))
    |> Map.put(:action, :insert)
    |> put_status()
    |> put_label()
    |> put_charge_unit()
    |> put_order_unit()
    |> put_minimum_order_quantity()
    |> validate()
  end

  def changeset(price, :update, params, locale \\ nil, default_locale \\ nil) do
    price = Proxy.put_account(price)
    default_locale = default_locale || price.account.default_locale
    locale = locale || default_locale

    price
    |> cast(params, castable_fields(price))
    |> Map.put(:action, :update)
    |> put_status()
    |> put_label()
    |> put_charge_unit()
    |> put_order_unit()
    |> put_minimum_order_quantity()
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  def changeset(price, :delete) do
    change(price)
    |> Map.put(:action, :delete)
    |> validate(:delete)
  end

  def get_estimate_average_rate(%{ estimate_average_percentage: nil }), do: nil
  def get_estimate_average_rate(%{ estimate_average_percentage: p }) do
    D.new(p) |> D.div(D.new(100))
  end

  def get_estimate_average_rate(%{ estimate_maximum_percentage: nil }), do: nil
  def get_estimate_average_rate(%{ estimate_maximum_percentage: p }) do
    D.new(p) |> D.div(D.new(100))
  end

  def balance(price) do
    children = Ecto.assoc(price, :children) |> Repo.all()
    charge_amount_cents = Enum.reduce(children, 0, fn(child, acc) ->
      acc + child.charge_amount_cents
    end)

    changeset = change(price, %{ charge_amount_cents: charge_amount_cents })
    Repo.update!(changeset)
  end

  def process(price, %{ action: :update }) do
    price = Repo.preload(price, :parent)

    if price.parent do
      {:ok, balance(price.parent)}
    else
      {:ok, price}
    end
  end
end
