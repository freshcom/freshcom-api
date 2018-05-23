defmodule BlueJet.Catalogue.Product do
  use BlueJet, :data

  use Trans,
    translates: [
      :name,
      :print_name,
      :short_name,
      :caption,
      :description,
      :custom_data
    ],
    container: :translations

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
      :print_name,
      :short_name,
      :caption,
      :description,
      :custom_data
    ]
  end

  @spec changeset(__MODULE__.t(), atom, map) :: Changeset.t()
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

  defp castable_fields(:insert) do
    writable_fields()
  end

  defp castable_fields(:update) do
    writable_fields() -- [:kind, :goods_id, :goods_type]
  end

  defp put_name(
         %{valid?: true, action: :insert, changes: %{name_sync: "sync_with_goods"}} = changeset
       ) do
    account = get_field(changeset, :account)
    goods_id = get_field(changeset, :goods_id)
    goods_type = get_field(changeset, :goods_type)

    goods =
      get_field(changeset, :goods) ||
        Proxy.get_goods(%{goods_type: goods_type, goods_id: goods_id, account: account})

    new_translations =
      changeset
      |> get_field(:translations)
      |> Translation.merge_translations(goods.translations, ["name"])

    changeset
    |> put_change(:name, goods.name)
    |> put_change(:goods, goods)
    |> put_change(:translations, new_translations)
  end

  defp put_name(changeset), do: changeset

  @spec validate(Changeset.t()) :: Changeset.t()
  def validate(changeset = %{action: :insert}) do
    changeset
    |> validate_required(required_fields(changeset))
    |> validate_status()
    |> validate_goods()
    |> validate_parent_id()
  end

  def validate(changeset = %{action: :update}) do
    changeset
    |> validate_required(required_fields(changeset))
    |> validate_status()
  end

  def validate(changeset), do: changeset

  defp required_fields(changeset) do
    kind = get_field(changeset, :kind)
    common = [:kind, :status, :name_sync, :name, :primary]

    case kind do
      "simple" ->
        common ++ [:goods_quantity, :maximum_public_order_quantity, :goods_id, :goods_type]

      "with_variants" ->
        common

      "combo" ->
        common ++ [:maximum_public_order_quantity]

      "variant" ->
        common ++
          [
            :parent_id,
            :goods_quantity,
            :maximum_public_order_quantity,
            :sort_index,
            :goods_id,
            :goods_type
          ]

      "item" ->
        common ++ [:parent_id, :goods_quantity, :sort_index, :goods_id, :goods_type]

      _ ->
        common
    end
  end

  defp validate_goods(changeset = %{valid?: true}) do
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

    goods =
      get_field(changeset, :goods) ||
        Proxy.get_goods(%{
          goods_type: goods_type,
          goods_id: goods_id,
          account: account
        })

    if goods do
      changeset
    else
      add_error(changeset, :goods, "is invalid")
    end
  end

  defp validate_status(changeset) do
    kind = get_field(changeset, :kind)
    validate_status(changeset, kind)
  end

  defp validate_status(%{changes: %{status: "active"}} = changeset, "variant") do
    validate_status(changeset, "simple")
  end

  defp validate_status(%{changes: %{status: "active"}, action: :insert} = changeset, kind)
       when kind in ["simple", "with_variants", "combo"] do
    add_error(
      changeset,
      :status,
      "Initial status of this kind of product cannot be active.",
      code: "cannot_be_active"
    )
  end

  defp validate_status(%{changes: %{status: "internal"}, action: :insert} = changeset, kind)
       when kind in ["simple", "with_variants", "combo"] do
    add_error(
      changeset,
      :status,
      "Initial status of this kind of product cannot be internal.",
      code: "cannot_be_internal"
    )
  end

  defp validate_status(%{changes: %{status: "active"}, action: :update} = changeset, "simple") do
    id = get_field(changeset, :id)

    active_price_count =
      Price.Query.for_product(id)
      |> Price.Query.filter_by(%{status: "active"})
      |> Repo.aggregate(:count, :id)

    case active_price_count do
      0 ->
        add_error(
          changeset,
          :status,
          "Product must have an active price in order to be marked active.",
          code: "require_active_price"
        )

      _ ->
        changeset
    end
  end

  defp validate_status(
         %{changes: %{status: "active"}, action: :update} = changeset,
         "with_variants"
       ) do
    id = get_field(changeset, :id)
    active_primary_item = Repo.get_by(__MODULE__, parent_id: id, status: "active", primary: true)

    case active_primary_item do
      nil ->
        add_error(
          changeset,
          :status,
          "Product with variants must have a primary active variant in order to be marked active.",
          code: "require_primary_active_variant"
        )

      _ ->
        changeset
    end
  end

  defp validate_status(%{changes: %{status: "active"}, action: :update} = changeset, "combo") do
    item_count =
      changeset.data
      |> Ecto.assoc(:items)
      |> Repo.aggregate(:count, :id)

    active_item_count =
      changeset.data
      |> Ecto.assoc(:items)
      |> Query.filter_by(%{status: "active"})
      |> Repo.aggregate(:count, :id)

    active_price_count =
      changeset.data
      |> Ecto.assoc(:prices)
      |> Price.Query.filter_by(%{status: "active"})
      |> Repo.aggregate(:count, :id)

    cond do
      item_count == 0 || active_item_count != item_count ->
        add_error(
          changeset,
          :status,
          "Product combo must have all of its items set to active in order to be marked active.",
          code: "require_all_item_be_active"
        )

      active_price_count == 0 ->
        add_error(
          changeset,
          :status,
          "Product combo require at least one active price in order to be marked active.",
          code: "require_active_price"
        )

      true ->
        changeset
    end
  end

  defp validate_status(%{changes: %{status: "internal"}} = changeset, "variant") do
    validate_status(changeset, "simple")
  end

  defp validate_status(%{changes: %{status: "internal"}} = changeset, "simple") do
    internal_price_count =
      changeset.data
      |> Ecto.assoc(:prices)
      |> Price.Query.filter_by(%{status: ["active", "internal"]})
      |> Repo.aggregate(:count, :id)

    if internal_price_count > 0 do
      changeset
    else
      add_error(
        changeset,
        :status,
        "Product must have a internal price in order to be marked internal.",
        code: "require_internal_price"
      )
    end
  end

  defp validate_status(%{changes: %{status: "internal"}} = changeset, "with_variants") do
    internal_variant_count =
      changeset.data
      |> Ecto.assoc(:variants)
      |> Query.filter_by(%{status: ["active", "internal"]})
      |> Repo.aggregate(:count, :id)

    case internal_variant_count do
      0 ->
        add_error(
          changeset,
          :status,
          "Product with variants must have at least one internal variant in order to be marked internal.",
          code: "require_internal_variant"
        )

      _ ->
        changeset
    end
  end

  defp validate_status(%{changes: %{status: "internal"}} = changeset, "combo") do
    item_count =
      changeset.data
      |> Ecto.assoc(:items)
      |> Repo.aggregate(:count, :id)

    internal_item_count =
      changeset.data
      |> Ecto.assoc(:items)
      |> Query.filter_by(%{status: ["active", "internal"]})
      |> Repo.aggregate(:count, :id)

    internal_price_count =
      changeset.data
      |> Ecto.assoc(:prices)
      |> Price.Query.filter_by(%{status: ["active", "internal"]})
      |> Repo.aggregate(:count, :id)

    cond do
      item_count == 0 || internal_item_count != item_count ->
        add_error(
          changeset,
          :status,
          "Product combo must have all of its item set to internal in order to be marked internal.",
          code: "require_all_item_be_internal"
        )

      internal_price_count == 0 ->
        add_error(
          changeset,
          :status,
          "A Product combo require at least one internal price in order to be marked internal.",
          code: "require_internal_price"
        )

      true ->
        changeset
    end
  end

  defp validate_status(changeset, _), do: changeset

  defp validate_parent_id(changeset = %{valid?: true, changes: %{product_id: product_id}}) do
    account_id = get_field(changeset, :account_id)
    product = Repo.get_by(Product, account_id: account_id, id: product_id)

    if product do
      changeset
    else
      add_error(changeset, :product, "is invalid", code: :invalid)
    end
  end

  defp validate_parent_id(changeset), do: changeset

  @doc """
  Reset the `primary` field of related product base on the fields of the given product.

  If the given product has `primary: true` then this function will mark all other
  product that have the same parent as the given product as `primary: false`,
  otherwise this function does nothing.

  Returns `{:ok, given_product}` if successful.
  """
  @spec reset_primary(__MODULE__.t) :: {:ok, __MODULE__.t}
  def reset_primary(%{ parent_id: nil } = product), do: {:ok, product}
  def reset_primary(%{ primary: false } = product), do: {:ok, product}

  def reset_primary(%{ id: id, parent_id: parent_id } = product) do
    Query.default()
    |> Query.filter_by(%{parent_id: parent_id})
    |> Query.except_id(id)
    |> Repo.update_all(set: [primary: false])

    {:ok, product}
  end
end
