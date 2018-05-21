defmodule BlueJet.Fulfillment.FulfillmentItem.Query do
  use BlueJet, :query
  use BlueJet.Query.Search, for: [
    :name,
    :caption
  ]
  use BlueJet.Query.Filter, for: [
    :id,
    :source_type,
    :source_id,
    :order_line_item_id,
    :fulfillment_id
  ]

  alias BlueJet.Fulfillment.FulfillmentItem

  def default() do
    from fi in FulfillmentItem
  end

  def preloads(_, _) do
    []
  end
end