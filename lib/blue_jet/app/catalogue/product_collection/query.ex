defmodule BlueJet.Catalogue.ProductCollection.Query do
  @behaviour BlueJet.Query

  use BlueJet, :query

  alias BlueJet.Catalogue.{Product, ProductCollection, ProductCollectionMembership}

  def identifiable_fields, do: [:id, :status]
  def filterable_fields, do: [:id, :status, :label]
  def searchable_fields, do: [:code, :name]

  def default() do
    from(pc in ProductCollection)
  end

  def get_by(q, i), do: filter_by(q, i, identifiable_fields())

  def filter_by(q, f), do: filter_by(q, f, filterable_fields())

  def search(q, k, l, d),
    do: search(q, k, l, d, searchable_fields(), ProductCollection.translatable_fields())

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
      |> order_by(desc: :sort_index, desc: :inserted_at)

    [
      memberships:
        {query, ProductCollectionMembership.Query.preloads(membership_preloads, options)}
    ]
  end

  def preloads(_, _) do
    []
  end
end
