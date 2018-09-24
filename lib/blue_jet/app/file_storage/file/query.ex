defmodule BlueJet.FileStorage.File.Query do
  @behaviour BlueJet.Query

  use BlueJet, :query

  alias BlueJet.FileStorage.File

  def identifiable_fields, do: [:id, :status]
  def filterable_fields, do: [:id, :status, :label, :content_type]
  def searchable_fields, do: [:id, :name, :code, :content_type]

  def default() do
    from(f in File)
  end

  def get_by(q, i), do: filter_by(q, i, identifiable_fields())

  def filter_by(q, f), do: filter_by(q, f, filterable_fields())

  def search(q, k, l, d),
    do: search(q, k, l, d, searchable_fields(), File.translatable_fields())
end
