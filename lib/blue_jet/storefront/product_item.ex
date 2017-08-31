defmodule BlueJet.Storefront.ProductItem do
  use BlueJet, :data

  use Trans, translates: [:name, :short_name, :custom_data], container: :translations

  alias Ecto.Changeset
  alias BlueJet.Translation
  alias BlueJet.Storefront.ProductItem
  alias BlueJet.Storefront.Product
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

  def put_name(changeset = %Changeset{ valid?: true, changes: %{ product_id: product_id, name_sync: "sync_with_product" } }, locale) do
    product = Repo.get!(Product, product_id) |> Translation.translate(locale)
    short_name = Changeset.get_field(changeset, :short_name)
    put_change(changeset, :name, "#{product.name} #{short_name}")
  end
  def put_name(changeset = %Changeset{ valid?: true, changes: %{ sku_id: sku_id, name_sync: "sync_with_source" } }, _) when not is_nil(sku_id) do
    sku = Repo.get!(Sku, sku_id)
    changeset = put_change(changeset, :name, "#{sku.name}")

    new_translations =
      changeset
      |> Changeset.get_field(:translations)
      |> Translation.merge_translations(sku.translations, ["name"])

    put_change(changeset, :translations, new_translations)
  end
  def put_name(changeset = %Changeset{ valid?: true, changes: %{ unlockable_id: unlockable_id, name_sync: "sync_with_source" } }, _) when not is_nil(unlockable_id) do
    unlockable = Repo.get!(Unlockable, unlockable_id)
    changeset = put_change(changeset, :name, "#{unlockable.name}")

    new_translations =
      changeset
      |> Changeset.get_field(:translations)
      |> Translation.merge_translations(unlockable.translations, ["name"])

    put_change(changeset, :translation, new_translations)
  end
  def put_name(changeset, _), do: changeset

  def query_for(product_id: product_id) do
    query = from pi in ProductItem,
      where: pi.product_id == ^product_id

    query
  end
end
