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
    :id,
    :status,
    :label,
    :content_type
  ]

  def default() do
    from f in File
  end

  def search(query, keyword, locale, default_locale) do
    search(query, @searchable_fields, keyword, locale, default_locale, File.translatable_fields())
  end

  def filter_by(query, filter) do
    filter_by(query, filter, @filterable_fields)
  end

  def uploaded(query) do
    from f in query, where: f.status == "uploaded"
  end
end