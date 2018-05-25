defmodule BlueJet.Catalogue.Product.Query do
  use BlueJet, :query
  use BlueJet.Query.Search, for: [
    :code,
    :name
  ]
  use BlueJet.Query.Filter, for: [
    :id,
    :status,
    :label,
    :kind
  ]

  alias BlueJet.Catalogue.{Product, ProductCollectionMembership, Price}

  def default() do
    from p in Product
  end

  def root(query) do
    from p in query, where: is_nil(p.parent_id)
  end

  def for_parent(query, nil) do
    root(query)
  end

  def for_parent(query, parent_id) do
    from p in query, where: p.parent_id == ^parent_id
  end

  def in_collection(query, nil), do: query

  def in_collection(query, collection_id) do
    from p in query,
      join: pcm in ProductCollectionMembership,
      on: pcm.product_id == p.id,
      where: pcm.collection_id == ^collection_id,
      order_by: [desc: pcm.sort_index]
  end

  def except_id(query, product_id) do
    from p in query, where: p.id != ^product_id
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
      |> Price.Query.filter_by(%{ status: "active" })
      |> order_by(desc: :minimum_order_quantity)

    [default_price: {query, Price.Query.preloads(price_preloads, options)}]
  end

  def preloads(_, _) do
    []
  end
end