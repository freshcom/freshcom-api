defmodule BlueJet.Notification.Trigger.Query do
  use BlueJet, :query

  alias BlueJet.Notification.Trigger

  @searchable_fields [
    :event
  ]

  @filterable_fields [
    :status,
    :event,
    :action_target,
    :action_type
  ]

  def default() do
    from t in Trigger, order_by: [desc: :updated_at]
  end

  def for_account(query, account_id) do
    from t in query, where: t.account_id == ^account_id
  end

  def search(query, keyword, locale, default_locale) do
    search(query, @searchable_fields, keyword, locale, default_locale, Order.translatable_fields())
  end

  def filter_by(query, filter) do
    filter_by(query, filter, @filterable_fields)
  end

  def preloads(_, _) do
    []
  end
end
