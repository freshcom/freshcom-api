defmodule BlueJet.Notification.Sms.Query do
  use BlueJet, :query

  alias BlueJet.Notification.Sms

  @searchable_fields [
    :to,
    :body
  ]

  @filterable_fields [
    :id,
    :status,
    :to
  ]

  def default() do
    from s in Sms
  end

  def for_account(query, account_id) do
    from s in query, where: s.account_id == ^account_id
  end

  def search(query, keyword) do
    search(query, @searchable_fields, keyword)
  end

  def filter_by(query, filter) do
    filter_by(query, filter, @filterable_fields)
  end

  def preloads(_, _) do
    []
  end
end