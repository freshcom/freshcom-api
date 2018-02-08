defmodule BlueJet.Catalogue.ProductCollection.Query do
  use BlueJet, :query

  alias BlueJet.Catalogue.{Product, ProductCollection, ProductCollectionMembership}

  @searchable_fields [
    :code,
    :name
  ]

  @filterable_fields [
    :status,
    :label
  ]

  def default() do
    from pc in ProductCollection, order_by: [desc: pc.sort_index]
  end

  def for_account(query, account_id) do
    from pc in query, where: pc.account_id == ^account_id
  end

  def search(query, keyword, locale, default_locale) do
    search(query, @searchable_fields, keyword, locale, default_locale, Product.translatable_fields())
  end

  def filter_by(query, filter) do
    filter_by(query, filter, @filterable_fields)
  end

  def preloads({:products, product_preloads}, options = [role: role]) when role in ["guest", "customer"] do
    query = Product.Query.default() |> Product.Query.active()
    [products: {query, Product.Query.preloads(product_preloads, options)}]
  end

  def preloads({:products, product_preloads}, options = [role: _]) do
    query = Product.Query.default()
    [products: {query, Product.Query.preloads(product_preloads, options)}]
  end

  def preloads({:memberships, membership_preloads}, options = [role: role]) when role in ["guest", "customer"] do
    query = ProductCollectionMembership.Query.default() |> ProductCollectionMembership.Query.with_product_status("active")
    [memberships: {query, ProductCollectionMembership.Query.preloads(membership_preloads, options)}]
  end

  def preloads({:memberships, membership_preloads}, options = [role: _]) do
    query = ProductCollectionMembership.Query.default()
    [memberships: {query, ProductCollectionMembership.Query.preloads(membership_preloads, options)}]
  end
end