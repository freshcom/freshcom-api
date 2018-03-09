defmodule BlueJet.Catalogue.Product.Query do
  use BlueJet, :query

  alias BlueJet.Catalogue.{Product, ProductCollectionMembership, Price}

  @searchable_fields [
    :code,
    :name
  ]

  @filterable_fields [
    :id,
    :status,
    :label,
    :kind
  ]

  def default() do
    from p in Product
  end

  def for_account(query, account_id) do
    from(p in query, where: p.account_id == ^account_id)
  end

  def default_order(query) do
    from p in query, order_by: [desc: p.updated_at]
  end

  def search(query, keyword, locale, default_locale) do
    search(query, @searchable_fields, keyword, locale, default_locale, Product.translatable_fields())
  end

  def filter_by(query, filter) do
    filter_by(query, filter, @filterable_fields)
  end

  def in_collection(query, nil), do: query
  def in_collection(query, collection_id) do
    from p in query,
      join: pcm in ProductCollectionMembership, on: pcm.product_id == p.id,
      where: pcm.collection_id == ^collection_id,
      order_by: [desc: pcm.sort_index]
  end

  def variant_default() do
    from(p in Product, where: p.kind == "variant", order_by: [desc: :updated_at])
  end

  def item_default() do
    from(p in Product, where: p.kind == "item", order_by: [desc: :updated_at])
  end

  def with_parent(query, parent_id) do
    from p in query, where: p.parent_id == ^parent_id
  end

  def preloads({:items, item_preloads}, options) do
    filter = get_preload_filter(options, :items)

    query =
      Product.Query.default()
      |> Product.Query.filter_by(filter)

    [items: {query, Product.Query.preloads(item_preloads, options)}]
  end

  def preloads({:variants, item_preloads}, options) do
    filter = get_preload_filter(options, :variants)

    query =
      Product.Query.default()
      |> Product.Query.filter_by(filter)

    [variants: {query, Product.Query.preloads(item_preloads, options)}]
  end

  def preloads({:prices, price_preloads}, options) do
    filter = get_preload_filter(options, :prices)

    query =
      Price.Query.default()
      |> Price.Query.filter_by(filter)

    [prices: {query, Price.Query.preloads(price_preloads, options)}]
  end

  def preloads({:default_price, price_preloads}, options) do
    query = Price.Query.active_by_moq()
    [default_price: {query, Price.Query.preloads(price_preloads, options)}]
  end

  def preloads(_, _) do
    []
  end

  def root(query) do
    from(p in query, where: is_nil(p.parent_id))
  end

  def active(query) do
    from(p in query, where: p.status == "active")
  end
end