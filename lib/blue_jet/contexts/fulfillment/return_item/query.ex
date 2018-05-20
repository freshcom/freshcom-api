defmodule BlueJet.Fulfillment.ReturnItem.Query do
  use BlueJet, :query

  alias BlueJet.Fulfillment.ReturnItem

  @filterable_fields [
    :id,
    :source_type,
    :source_id,
    :order_line_item_id,
    :fulfillment_item_id,
    :package_id,
    :status
  ]

  def default() do
    from fli in ReturnItem
  end

  def for_account(query, account_id) do
    from fli in query, where: fli.account_id == ^account_id
  end

  def filter_by(query, filter) do
    filter_by(query, filter, @filterable_fields)
  end

  def preloads(_, _) do
    []
  end
end