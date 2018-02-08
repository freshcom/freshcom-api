defmodule BlueJet.Catalogue.ProductCollectionMembership.Query do
  use BlueJet, :query

  alias BlueJet.Catalogue.{Product, ProductCollectionMembership}

  @filterable_fields [
    :collection_id,
    :product_id
  ]

  def default() do
    from pcm in ProductCollectionMembership, order_by: [desc: pcm.sort_index]
  end

  def for_account(query, account_id) do
    from pcm in query, where: pcm.account_id == ^account_id
  end

  def filter_by(query, filter) do
    filter_by(query, filter, @filterable_fields)
  end

  def for_collection(query, collection_id) do
    from pcm in query, where: pcm.collection_id == ^collection_id
  end

  def with_product_status(query, status) do
    from pcm in query,
      join: p in Product, on: p.id == pcm.product_id,
      where: p.status == ^status
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