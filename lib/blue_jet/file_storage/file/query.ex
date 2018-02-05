defmodule BlueJet.FileStorage.File.Query do
  use BlueJet, :query

  alias BlueJet.FileStorage.File

  @searchable_fields [
    :name,
    :content_type,
    :code,
    :id
  ]

  @filterable_fields [
    :status,
    :label,
    :content_type
  ]

  def default() do
    from(ef in File, order_by: [desc: ef.updated_at])
  end

  def search(query, keyword, locale, default_locale) do
    search(query, @searchable_fields, keyword, locale, default_locale, File.translatable_fields())
  end

  def filter_by(query, filter) do
    filter_by(query, filter, @filterable_fields)
  end

  def for_account(query, account_id) do
    from(ef in query, where: ef.account_id == ^account_id)
  end

  def uploaded(query) do
    from(ef in query, where: ef.status == "uploaded")
  end
end