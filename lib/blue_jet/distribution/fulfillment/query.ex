defmodule BlueJet.Distribution.Fulfillment.Query do
  use BlueJet, :query

  alias BlueJet.Distribution.{Fulfillment, FulfillmentLineItem}

  @filterable_fields [
    :source_type,
    :source_id
  ]

  def default() do
    from f in Fulfillment, order_by: [desc: f.inserted_at]
  end

  def for_account(query, account_id) do
    from f in query, where: f.account_id == ^account_id
  end

  def filter_by(query, filter) do
    filter_by(query, filter, @filterable_fields)
  end

  def preloads({:line_items, line_item_preloads}, options) do
    query = FulfillmentLineItem.Query.default()
    [line_items: {query, FulfillmentLineItem.Query.preloads(line_item_preloads, options)}]
  end

  def preloads(_, _) do
    []
  end
end