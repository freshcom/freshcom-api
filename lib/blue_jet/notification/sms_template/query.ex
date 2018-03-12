defmodule BlueJet.Notification.SmsTemplate.Query do
  use BlueJet, :query

  alias BlueJet.Notification.SmsTemplate

  @searchable_fields [
    :name,
    :to
  ]

  @filterable_fields [
    :id
  ]

  def default() do
    from st in SmsTemplate
  end

  def for_account(query, account_id) do
    from st in query, where: st.account_id == ^account_id
  end

  def search(query, keyword, locale, default_locale) do
    search(query, @searchable_fields, keyword, locale, default_locale, SmsTemplate.translatable_fields())
  end

  def filter_by(query, filter) do
    filter_by(query, filter, @filterable_fields)
  end

  def preloads(_, _) do
    []
  end
end