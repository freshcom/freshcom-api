defmodule BlueJet.Fulfillment.FulfillmentPackage.Query do
  use BlueJet, :query

  use BlueJet.Query.Search,
    for: [
      :name,
      :caption
    ]

  use BlueJet.Query.Filter,
    for: [
      :id,
      :status,
      :label,
      :customer_id,
      :order_id
    ]

  alias BlueJet.Fulfillment.{FulfillmentPackage, FulfillmentItem}

  def default() do
    from(f in FulfillmentPackage)
  end

  def preloads({:items, item_preloads}, options) do
    query = FulfillmentItem.Query.default()
    [items: {query, FulfillmentItem.Query.preloads(item_preloads, options)}]
  end

  def preloads(_, _) do
    []
  end
end
