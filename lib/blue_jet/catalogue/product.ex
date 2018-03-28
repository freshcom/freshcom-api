defmodule BlueJet.Catalogue.Product do
  @moduledoc """
  Product kinds:
  - simple
  - combo
  - with_variants
  """

  use BlueJet, :data

  use Trans, translates: [
    :name,
    :print_name,
    :short_name,
    :caption,
    :description,
    :custom_data
  ], container: :translations

  alias BlueJet.Catalogue.Price
  alias __MODULE__.{Query, Proxy}

  schema "products" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :status, :string, default: "draft"
    field :code, :string
    field :kind, :string, default: "simple"
    field :label, :string

    field :name_sync, :string, default: "disabled"
    field :name, :string
    field :short_name, :string
    field :print_name, :string

    field :sort_index, :integer, default: 1000
    field :goods_quantity, :integer, default: 1
    field :maximum_public_order_quantity, :integer, default: 999
    field :primary, :boolean, default: false
    field :auto_fulfill, :boolean, null: false, default: false

    field :caption, :string
    field :description, :string
    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    field :goods_id, Ecto.UUID
    field :goods_type, :string
    field :goods, :map, virtual: true

    field :avatar_id, Ecto.UUID
    field :avatar, :map, virtual: true

    field :file_collections, {:array, :map}, default: [], virtual: true

    timestamps()

    belongs_to :parent, __MODULE__
    has_many :items, __MODULE__, foreign_key: :parent_id
    has_many :variants, __MODULE__, foreign_key: :parent_id
    has_many :children, __MODULE__, foreign_key: :parent_id

    has_many :prices, Price, on_delete: :delete_all
    has_one :default_price, Price
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
    kind = get_field(changeset, :kind)

    common = [:kind, :status, :name_sync, :name, :primary]
    case kind do
      "simple" -> common ++ [:goods_quantity, :maximum_public_order_quantity, :goods_id, :goods_type]
      "with_variants" -> common
      "combo" -> common ++ [:maximum_public_order_quantity]
      "variant" -> common ++ [:parent_id, :goods_quantity, :maximum_public_order_quantity, :sort_index, :goods_id, :goods_type]
      "item" -> common ++ [:parent_id, :goods_quantity, :sort_index, :goods_id, :goods_type]
      _ -> common
    end
  end

  defp validate_goods(changeset = %{ valid?: true }) do
    kind = get_field(changeset, :kind)
    validate_goods(changeset, kind)
  end

  defp validate_goods(changeset), do: changeset

  defp validate_goods(changeset, "with_variants"), do: changeset
  defp validate_goods(changeset, "combo"), do: changeset

  defp validate_goods(changeset, _) do
    account = get_field(changeset, :account)
    goods_id = get_field(changeset, :goods_id)
    goods_type = get_field(changeset, :goods_type)
    account_id = get_field(changeset, :account_id)

    goods = get_field(changeset, :goods) || Proxy.get_goods(%{ goods_type: goods_type, goods_id: goods_id, account: account })

    if goods && goods.account_id == account_id do
      changeset
    else
      add_error(changeset, :goods, "is invalid")
    end
  end

  defp validate_status(changeset) do
    kind = get_field(changeset, :kind)
    validate_status(changeset, kind)
  end

  defp validate_status(changeset = %{ changes: %{ status: "active" } }, "variant") do
    validate_status(changeset, "simple")
  end

  defp validate_status(changeset = %{ changes: %{ status: "active" } }, "simple") do
    id = get_field(changeset, :id)

    active_price = if id do
      Repo.get_by(Price, product_id: id, status: "active")
    else
      nil
    end

    case active_price do
      nil -> add_error(changeset, :status, "A Product must have a Active Price in order to be marked Active.", [validation: "require_active_price", full_error_message: true])
      _ -> changeset
    end
  end

  defp validate_status(changeset = %{ changes: %{ status: "active" } }, "with_variants") do
    id = get_field(changeset, :id)

    active_primary_item = if id do
      Repo.get_by(__MODULE__, parent_id: id, status: "active", primary: true)
    else
      nil
    end

    case active_primary_item do
      nil -> add_error(changeset, :status, "A Product with variants must have a Primary Active Variant in order to be marked Active.", [validation: "require_primary_active_variant", full_error_message: true])
      _ -> changeset
    end
  end

  defp validate_status(changeset = %{ changes: %{ status: "active" } }, "combo") do
    items = Ecto.assoc(changeset.data, :items)
    item_count = Ecto.assoc(changeset.data, :items) |> Repo.aggregate(:count, :id)
    active_item_count = from(p in items, where: p.status == "active") |> Repo.aggregate(:count, :id)

    prices = Ecto.assoc(changeset.data, :prices)
    active_price_count = from(p in prices, where: p.status == "active") |> Repo.aggregate(:count, :id)

    cond do
      item_count == 0 || active_item_count != item_count -> add_error(changeset, :status, "A Product combo must have all of its Item set to Active in order to be marked Active.", [validation: "require_active_item", full_error_message: true])
      active_price_count == 0 -> add_error(changeset, :status, "A Product Combo require at least one Active Price in order to be marked Active.", [validation: "require_active_price", full_error_message: true])
      true -> changeset
    end
  end

  defp validate_status(changeset = %{ changes: %{ status: "internal" } }, "variant") do
    validate_status(changeset, "simple")
  end

  defp validate_status(changeset = %{ changes: %{ status: "internal" } }, "simple") do
    prices = Ecto.assoc(changeset.data, :prices)
    ai_price_count = from(p in prices, where: p.status in ["active", "internal"]) |> Repo.aggregate(:count, :id)

    if ai_price_count > 0 do
      changeset
    else
      add_error(changeset, :status, "A Product must have a Active/Internal Price in order to be marked Internal.", [validation: "require_internal_price", full_error_message: true])
    end
  end

  defp validate_status(changeset = %{ changes: %{ status: "internal" } }, "with_variants") do
    variants = Ecto.assoc(changeset.data, :variants)
    active_or_internal_variants = from(p in variants, where: p.status in ["active", "internal"])
    aiv_count = Repo.aggregate(active_or_internal_variants, :count, :id)

    case aiv_count do
      0 -> add_error(changeset, :status, "A Product with variants must have at least one Active/Internal Variant in order to be marked Internal.", [validation: "require_internal_variant", full_error_message: true])
      _ -> changeset
    end
  end

  defp validate_status(changeset = %{ changes: %{ status: "internal" } }, "combo") do
    items = Ecto.assoc(changeset.data, :items)
    item_count = items |> Repo.aggregate(:count, :id)
    aip_count = from(p in items, where: p.status in ["active", "internal"]) |> Repo.aggregate(:count, :id)

    prices = Ecto.assoc(changeset.data, :prices)
    ai_price_count = from(p in prices, where: p.status in ["active", "internal"]) |> Repo.aggregate(:count, :id)

    cond do
      item_count == 0 || aip_count != item_count -> add_error(changeset, :status, "A Product combo must have all of its Item set to Active/Internal in order to be marked Internal.", [validation: "require_internal_item", full_error_message: true])
      ai_price_count == 0 -> add_error(changeset, :status, "A Product combo require at least one Active/Internal Price in order to be marked Internal.", [validation: "require_internal_price", full_error_message: true])
      true -> changeset
    end
  end

  defp validate_status(changeset, _), do: changeset

  defp validate_parent_id(changeset = %{ valid?: true, changes: %{ product_id: product_id } }) do
    account_id = get_field(changeset, :account_id)
    product = Repo.get(Product, product_id)

    if product && product.account_id == account_id do
      changeset
    else
      add_error(changeset, :product, "is invalid", [validation: :must_exist])
    end
  end

  defp validate_parent_id(changeset), do: changeset

  def validate(changeset = %{ action: :insert }) do
    changeset
    |> validate_required(required_fields(changeset))
    |> validate_status()
    |> validate_goods()
    |> validate_parent_id()
  end

  def validate(changeset = %{ action: :update }) do
    changeset
    |> validate_required(required_fields(changeset))
    |> validate_status()
  end

  def validate(changeset), do: changeset

  #
  # MARK: Changeset
  #
  defp castable_fields(:insert) do
    writable_fields()
  end

  defp castable_fields(:update) do
    writable_fields() -- [:kind, :goods_id, :goods_type]
  end

  defp put_name(changeset = %{ action: :insert, changes: %{ name_sync: "sync_with_goods" } }) do
    account = get_field(changeset, :account)
    goods_id = get_field(changeset, :goods_id)
    goods_type = get_field(changeset, :goods_type)
    goods = get_field(changeset, :goods) || Proxy.get_goods(%{ goods_type: goods_type, goods_id: goods_id, account: account })

    if goods do
      new_translations =
        changeset
        |> get_field(:translations)
        |> Translation.merge_translations(goods.translations, ["name"])

      changeset
      |> put_change(:name, goods.name)
      |> put_change(:goods, goods)
      |> put_change(:translations, new_translations)
    else
      changeset
    end
  end

  defp put_name(changeset), do: changeset

  def changeset(product, :insert, params) do
    product
    |> cast(params, castable_fields(:insert))
    |> Map.put(:action, :insert)
    |> put_name()
    |> validate()
  end

  def changeset(product, :update, params, locale \\ nil, default_locale \\ nil) do
    product = Proxy.put_account(product)
    default_locale = default_locale || product.account.default_locale
    locale = locale || default_locale

    product
    |> cast(params, castable_fields(:update))
    |> Map.put(:action, :update)
    |> put_name()
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  def changeset(product, :delete) do
    change(product)
    |> Map.put(:action, :delete)
  end

  def process(product = %{ parent_id: parent_id }, %{ action: :update, changes: %{ primary: true } }) when not is_nil(parent_id) do
    Query.default()
    |> Query.with_parent(parent_id)
    |> Repo.update_all(set: [primary: false])

    {:ok, product}
  end

  def process(product, %{ action: :delete }) do
    Proxy.delete_avatar(product)

    {:ok, product}
  end

  def process(product, _), do: {:ok, product}
end
