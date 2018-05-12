defmodule BlueJet.Fulfillment.ReturnPackage.Query do
  use BlueJet, :query

  alias BlueJet.Fulfillment.{ReturnPackage, ReturnItem}

  @filterable_fields [
    :id,
    :order_id
  ]

  @searchable_fields [
    :name,
    :caption,
  ]

  def default() do
    from fp in ReturnPackage
  end

  def for_account(query, account_id) do
    from fp in query, where: fp.account_id == ^account_id
  end

  def filter_by(query, filter) do
    filter_by(query, filter, @filterable_fields)
  end

  def search(query, keyword, locale, default_locale) do
    search(query, @searchable_fields, keyword, locale, default_locale, ReturnPackage.translatable_fields())
  end

  def preloads({:items, item_preloads}, options) do
    query = ReturnItem.Query.default()
    [items: {query, ReturnItem.Query.preloads(item_preloads, options)}]
  end

  def preloads(_, _) do
    []
  end
end