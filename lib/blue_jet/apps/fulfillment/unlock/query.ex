defmodule BlueJet.Fulfillment.Unlock.Query do
  use BlueJet, :query

  alias BlueJet.Fulfillment.Unlock

  @filterable_fields [
    :id,
    :customer_id,
    :unlockable_id
  ]

  def default() do
    from u in Unlock
  end

  def filter_by(query, filter) do
    filter_by(query, filter, @filterable_fields)
  end

  def search(query, keyword, locale, default_locale) do
    search(query, [], keyword, locale, default_locale, Unlock.translatable_fields())
  end

  def for_account(query, account_id) do
    from(u in query, where: u.account_id == ^account_id)
  end

  def preloads(_, _) do
    []
  end
end