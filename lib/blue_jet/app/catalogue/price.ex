defmodule BlueJet.Catalogue.Price do
  @behaviour BlueJet.Data

  use BlueJet, :data

  alias BlueJet.Catalogue.Product
  alias __MODULE__.{Proxy, Query}

  schema "prices" do
    field :account_id, UUID
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

  @type t :: Ecto.Schema.t()

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
    [
      :name,
      :order_unit,
      :charge_unit,
      :caption,
      :description,
      :custom_data
    ]
  end

  @spec changeset(__MODULE__.t(), :insert, map) :: Changeset.t()
  def changeset(price, action, fields)
  def changeset(price, :insert, params) do
    price
    |> cast(params, castable_fields(:insert))
    |> Map.put(:action, :insert)
    |> put_parent_fields()
    |> put_order_unit()
    |> validate()
  end

  @spec changeset(__MODULE__.t(), :update, map, String.t()) :: Changeset.t()
  def changeset(price, action, fields, locale \\ nil)
  def changeset(price, :update, params, locale) do
    price = Proxy.put_account(price)
    default_locale = price.account.default_locale
    locale = locale || default_locale

    price
    |> cast(params, castable_fields(:update))
    |> Map.put(:action, :update)
    |> put_parent_fields()
    |> put_order_unit()
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  @spec changeset(__MODULE__.t(), :delete) :: Changeset.t()
  def changeset(price, action)
  def changeset(price, :delete) do
    change(price)
    |> Map.put(:action, :delete)
    |> validate(:delete)
  end

  defp castable_fields(:insert) do
    writable_fields()
  end

  defp castable_fields(:update) do
    writable_fields() -- [:product_id]
  end

  defp put_parent_fields(%{changes: %{parent_id: parent_id}} = changeset) do
    parent = Repo.get(__MODULE__, parent_id)

    new_translations =
      changeset
      |> get_field(:translations)
      |> Translation.merge_translations(parent.translations, ["charge_unit"])

    changeset
    |> put_change(:status, parent.status)
    |> put_change(:label, parent.label)
    |> put_change(:charge_unit, parent.charge_unit)
    |> put_change(:minimum_order_quantity, parent.minimum_order_quantity)
    |> put_change(:translations, new_translations)
  end

  defp put_parent_fields(changeset), do: changeset

  defp put_order_unit(%{changes: %{charge_unit: charge_unit}} = changeset) do
    case get_field(changeset, :estimate_by_default) do
      false ->
        put_change(changeset, :order_unit, charge_unit)

      _ ->
        changeset
    end
  end

  defp put_order_unit(%{changes: %{estimate_by_default: false}} = changeset) do
    charge_unit = get_field(changeset, :charge_unit)
    put_change(changeset, :order_unit, charge_unit)
  end

  defp put_order_unit(changeset), do: changeset

  @spec validate(Changeset.t()) :: Changeset.t()
  def validate(changeset) do
    changeset
    |> validate_required(required_fields(changeset))
    |> validate_assoc_account_scope(:product)
    |> validate_status()
  end

  def validate(%{data: price} = changeset, :delete) do
    if changeset(price, :update, %{status: "disabled"}).valid? do
      changeset
    else
      add_error(
        changeset,
        :status,
        "Can not delete the last active/internal price of a active/internal product",
        code: :cannot_delete_last_active_price
      )
    end
  end

  defp required_fields(changeset) do
    common_required = [
      :name,
      :product_id,
      :status,
      :currency_code,
      :charge_amount_cents,
      :charge_unit
    ]

    case get_field(changeset, :estimate_by_default) do
      true ->
        common_required ++
          [:order_unit, :estimate_average_percentage, :estimate_maximum_percentage]

      _ ->
        common_required
    end
  end

  defp validate_status(%{changes: %{status: "active"}} = changeset) do
    moq = get_field(changeset, :minimum_order_quantity)
    product_id = get_field(changeset, :product_id)

    price =
      Repo.get_by(
        __MODULE__,
        product_id: product_id,
        minimum_order_quantity: moq,
        status: "active"
      )

    case price do
      nil ->
        changeset

      _ ->
        add_error(
          changeset,
          :status,
          "An active price with the same minimum order quantity already exist.",
          code: :minimum_order_quantity_taken
        )
    end
  end

  defp validate_status(%{changes: %{status: _}} = changeset) do
    product_id = get_field(changeset, :product_id)
    product = Repo.get_by(Product, id: product_id)

    validate_status(changeset, product.status)
  end

  defp validate_status(changeset), do: changeset

  defp validate_status(%{changes: %{status: _}} = changeset, "active") do
    price_id = get_field(changeset, :id)
    product_id = get_field(changeset, :product_id)

    other_active_prices =
      cond do
        price_id && product_id ->
          Query.default()
          |> Query.filter_by(%{product_id: product_id, status: "active"})
          |> except(id: price_id)

        !price_id && product_id ->
          Query.default()
          |> Query.filter_by(%{product_id: product_id, status: "active"})
      end

    oap_count = Repo.aggregate(other_active_prices, :count, :id)

    case oap_count do
      0 ->
        add_error(
          changeset,
          :status,
          "Can not change status of the last active price of an active product.",
          code: :cannot_change_status_of_last_active_price
        )

      _ ->
        changeset
    end
  end

  defp validate_status(%{changes: %{status: "internal"}} = changeset, "internal"), do: changeset

  defp validate_status(%{changes: %{status: _}} = changeset, "internal") do
    price_id = get_field(changeset, :id)
    product_id = get_field(changeset, :product_id)

    other_active_or_internal_prices =
      Query.default()
      |> Query.filter_by(%{product_id: product_id, status: ["active", "internal"]})
      |> except(id: price_id)

    oaip_count = Repo.aggregate(other_active_or_internal_prices, :count, :id)

    case oaip_count do
      0 ->
        add_error(
          changeset,
          :status,
          "Can not change status of the last active/internal price of a internal product.",
          code: :cannot_change_status_of_last_internal_price
        )

      _ ->
        changeset
    end
  end

  defp validate_status(changeset, _), do: changeset
end
