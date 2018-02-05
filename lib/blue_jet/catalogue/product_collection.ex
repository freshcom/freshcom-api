defmodule BlueJet.Catalogue.ProductCollection do
  use BlueJet, :data

  use Trans, translates: [
    :name,
    :caption,
    :description,
    :custom_data
  ], container: :translations

  alias BlueJet.Catalogue.IdentityService
  alias BlueJet.Catalogue.Product
  alias BlueJet.Catalogue.ProductCollectionMembership

  schema "product_collections" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :status, :string, default: "draft"
    field :code, :string
    field :name, :string
    field :label, :string
    field :sort_index, :integer, default: 0

    field :caption, :string
    field :description, :string
    field :custom_data, :map, default: %{}
    field :translations, :map, defualt: %{}

    field :avatar_id, Ecto.UUID
    field :avatar, :map, virtual: true

    timestamps()

    has_many :memberships, ProductCollectionMembership, foreign_key: :collection_id
    has_many :products, through: [:memberships, :product]
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

  def validate(changeset) do
    changeset
    |> validate_required([:status, :name])
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(product_collection, params, locale \\ nil, default_locale \\ nil) do
    product_collection = %{ product_collection | account: get_account(product_collection) }
    default_locale = default_locale || product_collection.account.default_locale
    locale = locale || default_locale

    product_collection
    |> cast(params, writable_fields())
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  #
  # MARK: External Resources
  #
  def get_account(product) do
    product.account || IdentityService.get_account(product)
  end

  use BlueJet.FileStorage.Macro,
    put_external_resources: :file,
    field: :avatar

  use BlueJet.FileStorage.Macro,
    put_external_resources: :file_collection,
    field: :file_collections,
    owner_type: "ProductCollection"

  def put_external_resources(product_collection, _, _), do: product_collection

  defmodule Query do
    use BlueJet, :query

    alias BlueJet.Catalogue.ProductCollection

    def default() do
      from(pc in ProductCollection, order_by: [desc: pc.sort_index])
    end

    def for_account(query, account_id) do
      from(pc in query, where: pc.account_id == ^account_id)
    end

    def preloads({:products, product_preloads}, options = [role: role]) when role in ["guest", "customer"] do
      query = Product.Query.default() |> Product.Query.active()
      [products: {query, Product.Query.preloads(product_preloads, options)}]
    end

    def preloads({:products, product_preloads}, options = [role: _]) do
      query = Product.Query.default()
      [products: {query, Product.Query.preloads(product_preloads, options)}]
    end

    def preloads({:memberships, membership_preloads}, options = [role: role]) when role in ["guest", "customer"] do
      query = ProductCollectionMembership.Query.default() |> ProductCollectionMembership.Query.with_active_product()
      [memberships: {query, ProductCollectionMembership.Query.preloads(membership_preloads, options)}]
    end

    def preloads({:memberships, membership_preloads}, options = [role: _]) do
      query = ProductCollectionMembership.Query.default()
      [memberships: {query, ProductCollectionMembership.Query.preloads(membership_preloads, options)}]
    end
  end
end
