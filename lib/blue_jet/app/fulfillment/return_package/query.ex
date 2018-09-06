defmodule BlueJet.Fulfillment.ReturnPackage.Query do
  use BlueJet, :query

  use BlueJet.Query.Search,
    for: [
      :name,
      :caption
    ]

  use BlueJet.Query.Filter,
    for: [
      :id,
      :order_id
    ]

  alias BlueJet.Fulfillment.{ReturnPackage, ReturnItem}

  def default() do
    from(fp in ReturnPackage)
  end

  def preloads({:items, item_preloads}, options) do
    query = ReturnItem.Query.default()
    [items: {query, ReturnItem.Query.preloads(item_preloads, options)}]
  end

  def preloads(_, _) do
    []
  end
end
