defmodule BlueJet.Catalogue.ProductCollectionMembership.Query do
  @behaviour BlueJet.Query

  use BlueJet, :query

  alias BlueJet.Catalogue.{Product, ProductCollectionMembership}

  def identifiable_fields, do: [:id]
  def filterable_fields, do: [:collection_id, :product_id]

  def default() do
    from(pcm in ProductCollectionMembership, order_by: [desc: pcm.sort_index])
  end

  def get_by(q, i), do: filter_by(q, i, identifiable_fields())

  def filter_by(q, f), do: filter_by(q, f, filterable_fields())

  def search(query, nil, _, _), do: query
  def search(query, "", _, _), do: query

  def search(query, keyword, locale, default_locale) when is_nil(locale) or (locale == default_locale) do
    keyword = "%#{keyword}%"

    from(cm in query,
      join: p in Product,
      on: cm.product_id == p.id,
      or_where: ilike(fragment("?::varchar", p.name), ^keyword)
    )
  end

  def search(query, keyword, locale, _) do
    keyword = "%#{keyword}%"

    from(cm in query,
      join: p in Product,
      on: cm.product_id == p.id,
      or_where: ilike(fragment("?->?->>?", p.translations, ^locale, "name"), ^keyword)
    )
  end

  def preloads({:product, product_preloads}, options) do
    query = Product.Query.default()
    [product: {query, Product.Query.preloads(product_preloads, options)}]
  end

  def preloads(_, _) do
    []
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
end
