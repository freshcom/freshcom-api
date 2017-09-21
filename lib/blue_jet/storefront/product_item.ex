defmodule BlueJet.Storefront.ProductItem do
  use BlueJet, :data

  use Trans, translates: [:name, :short_name, :custom_data], container: :translations

  alias Ecto.Changeset
  alias BlueJet.Translation
  alias BlueJet.Storefront.ProductItem
  alias BlueJet.Storefront.Product
  alias BlueJet.Storefront.Price
  alias BlueJet.Identity.Account
  alias BlueJet.Inventory.Sku
  alias BlueJet.Inventory.Unlockable

  schema "product_items" do
    field :code, :string
    field :status, :string, default: "draft"
    field :name_sync, :string, default: "disabled"
    field :name, :string
    field :short_name, :string
    field :sort_index, :integer, default: 9999
    field :source_quantity, :integer, default: 1
    field :maximum_public_order_quantity, :integer, default: 9999
    field :primary, :boolean, default: false

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    timestamps()

    belongs_to :account, Account
    belongs_to :product, Product
    belongs_to :sku, Sku
    belongs_to :unlockable, Unlockable
    has_many :prices, Price, on_delete: :delete_all
    has_one :default_price, Price
  end

  def system_fields do
    [
      :id,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    ProductItem.__schema__(:fields) -- system_fields()
  end

  def translatable_fields do
    ProductItem.__trans__(:fields)
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields() -- [:status]
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:account_id, :product_id]
  end

  def required_fields do
    [
      :status, :name, :sort_index, :source_quantity, :maximum_public_order_quantity, :primary,
      :custom_data, :product_id
    ]
  end

  def validate(changeset) do
    changeset
    |> validate_required(required_fields())
    |> validate_required_exactly_one([:sku_id, :unlockable_id], :relationships)
    |> validate_assoc_account_scope([:product, :sku, :unlockable])
    |> validate_status()
  end

  # TODO: handle the case where ProductItem is not yet created
  def validate_status(changeset) do
    product_id = get_field(changeset, :product_id)

    if product_id do
      product = Repo.get(Product, product_id)
      validate_status(changeset, product)
    else
      changeset
    end
  end

  defp validate_status(changeset = %Changeset{ changes: %{ status: "active" } }, %Product{ item_mode: "any" }) do
    prices = Ecto.assoc(changeset.data, :prices)
    active_prices = from(p in prices, where: p.status == "active")
    ap_count = Repo.aggregate(active_prices, :count, :id)

    case ap_count do
      0 -> Changeset.add_error(changeset, :status, "A Product Item must have at least one Active Price in order to be marked Active.", [validation: "require_at_least_one_active_price", full_error_message: true])
      _ -> changeset
    end
  end
  defp validate_status(changeset = %Changeset{ changes: %{ status: _ } }, product = %Product{ item_mode: "any", status: "active" }) do
    pi_id = get_field(changeset, :id)
    product_items = Ecto.assoc(product, :items)

    other_active_pi = from(pi in product_items, where: pi.id != ^pi_id, where: pi.status == "active")
    oapi_count = Repo.aggregate(other_active_pi, :count, :id)

    case oapi_count do
      0 -> Changeset.add_error(changeset, :status, "Can not change status of the only Active Product Item of a Active Product.", [validation: "cannot_change_status_of_only_active_item_of_active_product", full_error_message: true])
      _ -> changeset
    end
  end
  defp validate_status(changeset = %Changeset{ data: %{ status: "active" }, changes: %{ status: "internal" } }, product = %Product{ item_mode: "any", status: "internal" }), do: changeset
  defp validate_status(changeset = %Changeset{ changes: %{ status: _ } }, product = %Product{ item_mode: "any", status: "internal" }) do
    pi_id = get_field(changeset, :id)
    product_items = Ecto.assoc(product, :items)

    other_active_or_internal_pi = from(pi in product_items, where: pi.id != ^pi_id, where: pi.status in ["active", "internal"])
    oaipi_count = Repo.aggregate(other_active_or_internal_pi, :count, :id)

    case oaipi_count do
      0 -> Changeset.add_error(changeset, :status, "Can not change status of the only Internal Product Item of a Internal Product.", [validation: "cannot_change_status_of_only_internal_item_of_internal_product", full_error_message: true])
      _ -> changeset
    end
  end
  defp validate_status(changeset = %Changeset{ changes: %{ status: "internal" } }, product = %Product{ item_mode: "any" }) do
    prices = Ecto.assoc(changeset.data, :prices)
    active_or_internal_prices = from(p in prices, where: p.status in ["active", "internal"])
    aip_count = Repo.aggregate(active_or_internal_prices, :count, :id)

    case aip_count do
      0 -> Changeset.add_error(changeset, :status, "A Product Item must have at least one Active or Internal Price in order to be marked Internal.", [validation: "require_at_least_one_internal_price", full_error_message: true])
      _ -> changeset
    end
  end
  defp validate_status(changeset = %Changeset{ changes: %{ status: "active" } }, %Product{ item_mode: "all" }), do: changeset
  defp validate_status(changeset = %Changeset{ data: %{ status: "active" }, changes: %{ status: _ } }, product = %Product{ item_mode: "all", status: "active" }) do
    Changeset.add_error(changeset, :status, "Can not change the status of a Product Item that is part of a Active Product with Item Mode set to All.", [validation: "cannot_change_status_of_item_of_active_product_combo"])
  end
  defp validate_status(changeset = %Changeset{ data: %{ status: "internal" }, changes: %{ status: _ } }, product = %Product{ item_mode: "all", status: "internal" }) do
    Changeset.add_error(changeset, :status, "Can not change the status of a Product Item that is part of a Internal Product with Item Mode set to All.", [validation: "cannot_change_status_of_item_of_internal_product_combo"])
  end
  defp validate_status(changeset = %Changeset{ data: %{ status: "active" }, changes: %{ status: "internal" } }, product = %Product{ item_mode: "all", status: "internal" }), do: changeset
  defp validate_status(changeset = %Changeset{ data: %{ status: "active" }, changes: %{ status: _ } }, product = %Product{ item_mode: "all", status: "internal" }) do
    Changeset.add_error(changeset, :status, "Can not change the status of a Product Item that is part of a Internal Product with Item Mode set to All.", [validation: "cannot_change_status_of_item_of_internal_product_combo"])
  end
  defp validate_status(changeset, _), do: changeset

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}, locale \\ "en") do
    struct
    |> cast(params, castable_fields(struct))
    |> put_name(locale)
    |> validate()
    |> Translation.put_change(translatable_fields(), locale)
  end

  def put_name(changeset = %Changeset{ valid?: true, changes: %{ name_sync: "sync_with_source" } }, _) do
    source = if get_field(changeset, :sku_id) do
      Repo.get!(Sku, get_field(changeset, :sku_id))
    else
      Repo.get!(Unlockable, get_field(changeset, :unlockable_id))
    end
    changeset = put_change(changeset, :name, "#{source.name}")

    new_translations =
      changeset
      |> Changeset.get_field(:translations)
      |> Translation.merge_translations(source.translations, ["name"])

    put_change(changeset, :translations, new_translations)
  end
  def put_name(changeset = %Changeset{ valid?: true }, locale) do
    if get_field(changeset, :name_sync) == "sync_with_product" do
      product_id = get_field(changeset, :product_id)
      product = Repo.get!(Product, product_id) |> Translation.translate(locale)

      # If this ProductItem already have localized short_name we will use it
      # for the corresponding locale
      old_translations = Changeset.get_field(changeset, :translations)
      new_translations = Translation.merge_translations(old_translations, product.translations, ["name"])

      new_translations = Enum.reduce(new_translations, new_translations, fn({locale, locale_struct}, acc) ->
        localized_short_name = old_translations[locale]["short_name"]

        new_locale_struct = if localized_short_name do
          Map.put(locale_struct, "name", locale_struct["name"] + " " + localized_short_name)
        else
          locale_struct
        end

        Map.put(acc, locale, new_locale_struct)
      end)

      changeset = put_change(changeset, :translations, new_translations)

      # Overwrite the current locale short_name as normal
      short_name = Changeset.get_field(changeset, :short_name)
      put_change(changeset, :name, "#{product.name} #{short_name}")
    else
      changeset
    end
  end
  def put_name(changeset, _), do: changeset

  def query_for(product_id: product_id) do
    query = from pi in ProductItem,
      where: pi.product_id == ^product_id

    query
  end

  def query() do
    from(pi in ProductItem, order_by: [desc: pi.sort_index, desc: pi.inserted_at])
  end

  def preload(struct_or_structs, targets) when length(targets) == 0 do
    struct_or_structs
  end
  def preload(struct_or_structs, targets) when is_list(targets) do
    [target | rest] = targets

    struct_or_structs
    |> Repo.preload(preload_keyword(target))
    |> ProductItem.preload(rest)
  end

  def preload_keyword({:sku, sku_preloads}) do
    [sku: {Sku.query(), Sku.preload_keyword(sku_preloads)}]
  end
  def preload_keyword(:product) do
    [product: Product.query()]
  end
  def preload_keyword({:product, product_preloads}) do
    [product: Product.query()]
  end
  def preload_keyword(:prices) do
    [prices: Price.query()]
  end
  def preload_keyword(:default_price) do
    [default_price: from(p in Price, where: p.status == "active", order_by: [asc: :minimum_order_quantity])]
  end
end
