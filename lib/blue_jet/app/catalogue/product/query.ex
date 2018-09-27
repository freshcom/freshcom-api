defmodule BlueJet.Catalogue.Product.Query do
  @behaviour BlueJet.Query

  use BlueJet, :query

  alias BlueJet.Catalogue.{Product, ProductCollectionMembership, Price}

  def identifiable_fields, do: [:id, :status, :kind, :parent_id]
  def filterable_fields, do: [:id, :status, :label, :kind, :parent_id]
  def searchable_fields, do: [:code, :name]

  def default() do
    from(p in Product)
  end

  def get_by(q, i), do: filter_by(q, i, identifiable_fields())

  def filter_by(q, f), do: filter_by(q, f, filterable_fields())

  def search(q, k, l, d),
    do: search(q, k, l, d, searchable_fields(), Product.translatable_fields())

  def root(query) do
    from(p in query, where: is_nil(p.parent_id))
  end

  def in_collection(query, nil), do: query

  def in_collection(query, collection_id) do
    from(
      p in query,
      join: pcm in ProductCollectionMembership,
      on: pcm.product_id == p.id,
      where: pcm.collection_id == ^collection_id,
      order_by: [desc: pcm.sort_index]
    )
  end

  def preloads({:items, item_preloads}, options) do
    filter = get_preload_filter(options, :items)

    query =
      default()
      |> filter_by(filter)

    [items: {query, preloads(item_preloads, options)}]
  end

  def preloads({:variants, item_preloads}, options) do
    filter = get_preload_filter(options, :variants)

    query =
      default()
      |> filter_by(filter)

    [variants: {query, preloads(item_preloads, options)}]
  end

  def preloads({:children, item_preloads}, options) do
    filter = get_preload_filter(options, :children)

    query =
      default()
      |> filter_by(filter)

    [children: {query, Product.Query.preloads(item_preloads, options)}]
  end

  def preloads({:prices, price_preloads}, options) do
    filter = get_preload_filter(options, :prices)

    query =
      Price.Query.default()
      |> Price.Query.filter_by(filter)

    [prices: {query, Price.Query.preloads(price_preloads, options)}]
  end

  def preloads({:default_price, price_preloads}, options) do
    query =
      Price.Query.default()
      |> Price.Query.filter_by(%{status: "active"})
      |> order_by(asc: :minimum_order_quantity)

    [default_price: {query, Price.Query.preloads(price_preloads, options)}]
  end

  def preloads(_, _) do
    []
  end
end
