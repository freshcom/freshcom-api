defmodule BlueJet.Catalogue.ProductCollectionMembership do
  use BlueJet, :data

  alias BlueJet.Catalogue.ProductCollectionMembership
  alias BlueJet.Catalogue.ProductCollection
  alias BlueJet.Catalogue.Product

  schema "product_collection_memberships" do
    field :account_id, Ecto.UUID
    field :sort_index, :integer, default: 100

    timestamps()

    belongs_to :collection, ProductCollection
    belongs_to :product, Product
  end

  def system_fields do
    [
      :id,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    ProductCollectionMembership.__schema__(:fields) -- system_fields()
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:account_id, :collection_id, :product_id]
  end

  def validate(changeset) do
    changeset
    |> validate_required([:account_id, :collection_id, :product_id])
    |> foreign_key_constraint(:account_id)
    |> unique_constraint(:product_id, name: :product_collection_memberships_product_id_collection_id_index)
    |> validate_assoc_account_scope([:collection, :product])
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
