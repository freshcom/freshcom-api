defmodule BlueJet.Balance.Refund.Query do
  use BlueJet, :query

  alias BlueJet.Balance.Refund

  def default() do
    from(r in Refund, order_by: [desc: :updated_at])
  end

  def for_account(query, account_id) do
    from(r in query, where: r.account_id == ^account_id)
  end

  def search(query, keyword, locale, default_locale) do
    search(query, @searchable_fields, keyword, locale, default_locale, Refund.translatable_fields())
  end

  def filter_by(query, filter) do
    filter_by(query, filter, @filterable_fields)
  end
end