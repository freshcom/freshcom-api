defmodule BlueJet.Fulfillment.FulfillmentItem.Query do
  use BlueJet, :query

  alias BlueJet.Fulfillment.FulfillmentItem

  @filterable_fields [
    :id,
    :source_type,
    :source_id,
    :order_line_item_id,
    :fulfillment_id
  ]

  def default() do
    from fi in FulfillmentItem
  end

  def for_account(query, account_id) do
    from fi in query, where: fi.account_id == ^account_id
  end

  def filter_by(query, filter) do
    filter_by(query, filter, @filterable_fields)
  end

  def preloads(_, _) do
    []
  end
end