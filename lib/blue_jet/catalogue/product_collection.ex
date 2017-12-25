defmodule BlueJet.Catalogue.ProductCollection do
  use BlueJet, :data

  use Trans, translates: [
    :name,
    :caption,
    :description,
    :custom_data
  ], container: :translations

  alias BlueJet.Translation
  alias BlueJet.Catalogue.Product
  alias BlueJet.Catalogue.ProductCollection
  alias BlueJet.Catalogue.ProductCollectionMembership

  schema "product_collections" do
    field :account_id, Ecto.UUID
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

  def system_fields do
    [
      :id,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    ProductCollection.__schema__(:fields) -- system_fields()
  end

  def translatable_fields do
    ProductCollection.__trans__(:fields)
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:account_id]
  end

  def validate(changeset) do
    changeset
    |> validate_required([:account_id, :status, :name])
    |> foreign_key_constraint(:account_id)
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params, locale \\ nil, default_locale \\ nil) do
    struct
    |> cast(params, castable_fields(struct))
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  #
  # External Resources
  #
  use BlueJet.FileStorage.Macro,
    put_external_resources: :external_file,
    field: :avatar

  use BlueJet.FileStorage.Macro,
    put_external_resources: :external_file_collection,
    field: :external_file_collections,
    owner_type: "ProductCollection"

  def put_external_resources(product_collection, _, _), do: product_collection

  defmodule Query do
    use BlueJet, :query

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
