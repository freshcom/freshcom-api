defmodule BlueJet.Fulfillment.FulfillmentPackage.Query do
  use BlueJet, :query

  alias BlueJet.Fulfillment.{FulfillmentPackage, FulfillmentItem}

  @filterable_fields [
    :id,
    :status,
    :label,
    :customer_id,
    :order_id
  ]

  @searchable_fields [
    :name,
    :caption,
  ]

  def default() do
    from f in FulfillmentPackage
  end

  def filter_by(query, filter) do
    filter_by(query, filter, @filterable_fields)
  end

  def search(query, keyword, locale, default_locale) do
    search(query, @searchable_fields, keyword, locale, default_locale, FulfillmentPackage.translatable_fields())
  end

  def preloads({:items, item_preloads}, options) do
    query = FulfillmentItem.Query.default()
    [items: {query, FulfillmentItem.Query.preloads(item_preloads, options)}]
  end

  def preloads(_, _) do
    []
  end
end