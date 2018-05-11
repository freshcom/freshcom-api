defmodule BlueJet.Notification.Email.Query do
  use BlueJet, :query

  alias BlueJet.Notification.Email

  @searchable_fields [
    :to,
    :from,
    :subject,
    :reply_to
  ]

  @filterable_fields [
    :id,
    :status
  ]

  def default() do
    from e in Email
  end

  def for_account(query, account_id) do
    from e in query, where: e.account_id == ^account_id
  end

  def search(query, keyword) do
    search(query, @searchable_fields, keyword)
  end

  def search(query, keyword, _, _) do
    search(query, @searchable_fields, keyword)
  end

  def filter_by(query, filter) do
    filter_by(query, filter, @filterable_fields)
  end

  def preloads(_, _) do
    []
  end
end