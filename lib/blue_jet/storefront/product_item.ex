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
    field :status, :string
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
    has_many :prices, Price
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
    writable_fields()
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
  end

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

  def preload_keyword({:sku, sku_preloads}) do
    [sku: {Sku.query(), Sku.preload_keyword(sku_preloads)}]
  end

  def default_price(%ProductItem{ id: id }) do
    from(p in Price,
      where: p.product_item_id == ^id,
      where: p.minimum_order_quantity == 1,
      where: p.status == 'active')
    |> Repo.one()
  end
end
