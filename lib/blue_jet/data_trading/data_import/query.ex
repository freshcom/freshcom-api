defmodule BlueJet.DataTrading.DataImport.Query do
  use BlueJet, :query

  alias BlueJet.DataTrading.DataImport

  @filterable_fields [
    :id,
    :status
  ]

  def default() do
    from di in DataImport
  end

  def for_account(query, account_id) do
    from di in query, where: di.account_id == ^account_id
  end

  def filter_by(query, filter) do
    filter_by(query, filter, @filterable_fields)
  end
end