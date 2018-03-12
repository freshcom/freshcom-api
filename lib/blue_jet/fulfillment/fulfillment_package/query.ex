defmodule BlueJet.Fulfillment.FulfillmentPackage.Query do
  use BlueJet, :query

  alias BlueJet.Fulfillment.{FulfillmentPackage, FulfillmentItem}

  @filterable_fields [
    :id,
    :order_id
  ]

  def default() do
    from f in FulfillmentPackage
  end

  def for_account(query, account_id) do
    from f in query, where: f.account_id == ^account_id
  end

  def filter_by(query, filter) do
    filter_by(query, filter, @filterable_fields)
  end

  def preloads({:items, item_preloads}, options) do
    query = FulfillmentItem.Query.default()
    [items: {query, FulfillmentItem.Query.preloads(item_preloads, options)}]
  end

  def preloads(_, _) do
    []
  end
end