defmodule BlueJet.Notification.EmailTemplate.Query do
  use BlueJet, :query

  alias BlueJet.Notification.EmailTemplate

  @searchable_fields [
    :name,
    :subject,
    :to,
    :reply_to
  ]

  @filterable_fields [
    :id,
    :from
  ]

  def default() do
    from et in EmailTemplate
  end

  def search(query, keyword, locale, default_locale) do
    search(query, @searchable_fields, keyword, locale, default_locale, EmailTemplate.translatable_fields())
  end

  def filter_by(query, filter) do
    filter_by(query, filter, @filterable_fields)
  end

  def preloads(_, _) do
    []
  end
end