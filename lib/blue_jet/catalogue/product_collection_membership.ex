defmodule BlueJet.Catalogue.ProductCollectionMembership do
  use BlueJet, :data

  alias BlueJet.Catalogue.ProductCollection
  alias BlueJet.Catalogue.Product

  schema "product_collection_memberships" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true
    field :sort_index, :integer, default: 100

    timestamps()

    belongs_to :collection, ProductCollection
    belongs_to :product, Product
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

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:collection_id, :product_id]
  end

  defp validate_collection_id(changeset = %{ valid?: true, changes: %{ collection_id: collection_id } }) do
    account_id = get_field(changeset, :account_id)
    collection = Repo.get(ProductCollection, collection_id)

    if collection && collection.account_id == account_id do
      changeset
    else
      add_error(changeset, :collection, "is invalid", [validation: :must_exist])
    end
  end

  defp validate_product_id(changeset = %{ valid?: true, changes: %{ product_id: product_id } }) do
    account_id = get_field(changeset, :account_id)
    product = Repo.get(Product, product_id)

    if product && product.account_id == account_id do
      changeset
    else
      add_error(changeset, :product, "is invalid", [validation: :must_exist])
    end
  end

  def validate(changeset) do
    changeset
    |> validate_required([:collection_id, :product_id])
    |> unique_constraint(:product_id, name: :product_collection_memberships_product_id_collection_id_index)
    |> validate_collection_id()
    |> validate_product_id()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, castable_fields(struct))
    |> validate()
  end

  defmodule Query do
    use BlueJet, :query

    alias BlueJet.Catalogue.ProductCollectionMembership

    def default() do
      from pcm in ProductCollectionMembership, order_by: [desc: pcm.sort_index]
    end

    def for_account(query, account_id) do
      from pcm in query, where: pcm.account_id == ^account_id
    end

    def for_collection(query, collection_id) do
      from pcm in query, where: pcm.collection_id == ^collection_id
    end

    def with_active_product(query) do
      from pcm in query,
        join: p in Product, on: p.id == pcm.product_id,
        where: p.status == "active"
    end

    def preloads({:product, product_preloads}, options = [role: role]) when role in ["guest", "customer"] do
      query = Product.Query.default() |> Product.Query.active()
      [product: {query, Product.Query.preloads(product_preloads, options)}]
    end

    def preloads({:product, product_preloads}, options = [role: _]) do
      query = Product.Query.default()
      [product: {query, Product.Query.preloads(product_preloads, options)}]
    end

    def preloads(_, _) do
      []
    end
  end
end
