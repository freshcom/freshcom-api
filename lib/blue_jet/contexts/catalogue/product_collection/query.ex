defmodule BlueJet.Catalogue.ProductCollection.Query do
  use BlueJet, :query
  use BlueJet.Query.Search, for: [
    :code,
    :name
  ]
  use BlueJet.Query.Filter, for: [
    :id,
    :status,
    :label
  ]

  alias BlueJet.Catalogue.{Product, ProductCollection, ProductCollectionMembership}

  def default() do
    from pc in ProductCollection
  end

  def preloads({:products, product_preloads}, options) do
    query = Product.Query.default()
    [products: {query, Product.Query.preloads(product_preloads, options)}]
  end

  def preloads({:memberships, membership_preloads}, options) do
    filter = get_preload_filter(options, :memberships)

    query =
      ProductCollectionMembership.Query.default()
      |> ProductCollectionMembership.Query.with_product_status(filter[:product_status])
      |> BlueJet.Query.paginate(size: 10, number: 1)
      |> order_by([desc: :sort_index, desc: :inserted_at])

    [memberships: {query, ProductCollectionMembership.Query.preloads(membership_preloads, options)}]
  end

  def preloads(_, _) do
    []
  end
end