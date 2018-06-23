defmodule BlueJet.Fulfillment.ReturnItem.Query do
  use BlueJet, :query

  use BlueJet.Query.Filter,
    for: [
      :id,
      :source_type,
      :source_id,
      :order_line_item_id,
      :fulfillment_item_id,
      :package_id,
      :status
    ]

  alias BlueJet.Fulfillment.ReturnItem

  def default() do
    from(fli in ReturnItem)
  end

  def preloads(_, _) do
    []
  end
end
