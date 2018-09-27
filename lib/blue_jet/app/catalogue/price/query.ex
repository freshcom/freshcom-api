defmodule BlueJet.Catalogue.Price.Query do
  @behaviour BlueJet.Query

  use BlueJet, :query

  alias BlueJet.Catalogue.{Product, Price}

  def identifiable_fields, do: [:id, :status, :product_id]
  def filterable_fields, do: [:status, :label, :product_id]
  def searchable_fields, do: [:name, :caption]

  def default() do
    from(p in Price)
  end

  def get_by(q, i), do: filter_by(q, i, identifiable_fields())

  def filter_by(q, f), do: filter_by(q, f, filterable_fields())

  def search(q, k, l, d),
    do: search(q, k, l, d, searchable_fields(), Price.translatable_fields())

  def preloads({:product, product_preloads}, options) do
    query = Product.Query.default()
    [product: {query, Product.Query.preloads(product_preloads, options)}]
  end

  def preloads({:children, children_preloads}, options) do
    query = Price.Query.default()
    [children: {query, Price.Query.preloads(children_preloads, options)}]
  end

  def preloads(_, _) do
    []
  end

  def for_product(product_id) do
    from(
      p in Price,
      where: p.product_id == ^product_id,
      order_by: [asc: :minimum_order_quantity]
    )
  end

  def for_order_quantity(query, nil), do: query

  def for_order_quantity(query, order_quantity) do
    from(p in query, where: p.minimum_order_quantity <= ^order_quantity)
  end
end
