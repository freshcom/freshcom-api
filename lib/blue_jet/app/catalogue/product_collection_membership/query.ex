defmodule BlueJet.Catalogue.ProductCollectionMembership.Query do
  use BlueJet, :query

  use BlueJet.Query.Filter,
    for: [
      :collection_id,
      :product_id
    ]

  alias BlueJet.Catalogue.{Product, ProductCollectionMembership}

  def default() do
    from(pcm in ProductCollectionMembership, order_by: [desc: pcm.sort_index])
  end

  def for_collection(query, collection_id) do
    from(pcm in query, where: pcm.collection_id == ^collection_id)
  end

  def with_product_status(query, nil) do
    query
  end

  def with_product_status(query, status) do
    from(pcm in query, join: p in Product, on: p.id == pcm.product_id, where: p.status == ^status)
  end

  def preloads({:product, product_preloads}, options) do
    query = Product.Query.default()
    [product: {query, Product.Query.preloads(product_preloads, options)}]
  end

  def preloads(_, _) do
    []
  end
end
