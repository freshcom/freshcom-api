defmodule BlueJet.Catalogue.Price.Query do
  use BlueJet, :query

  alias BlueJet.Catalogue.{Product, Price}

  @filterable_fields [
    :status,
    :label,
    :kind
  ]

  def default() do
    from p in Price
  end

  def for_account(query, account_id) do
    from p in query, where: p.account_id == ^account_id
  end

  def filter_by(query, filter) do
    filter_by(query, filter, @filterable_fields)
  end

  def for_product(product_id) do
    from p in Price,
      where: p.product_id == ^product_id,
      order_by: [asc: :minimum_order_quantity]
  end

  def with_order_quantity(query, nil), do: query

  def with_order_quantity(query, order_quantity) do
    from p in query, where: p.minimum_order_quantity <= ^order_quantity
  end

  def with_status(query, status) do
    from p in query, where: p.status == ^status
  end

  def active_by_moq() do
    from p in Price, where: p.status == "active", order_by: [asc: :minimum_order_quantity]
  end

  def active(query) do
    from p in query, where: p.status == "active"
  end

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
end