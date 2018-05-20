defmodule BlueJet.FileStorage.FileCollection.Query do
  use BlueJet, :query

  alias BlueJet.FileStorage.{FileCollection, File, FileCollectionMembership}

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
    :owner_id,
    :owner_type,
    :content_type
  ]

  def default() do
    from fc in FileCollection
  end

  def search(query, keyword, locale, default_locale) do
    search(query, @searchable_fields, keyword, locale, default_locale, FileCollection.translatable_fields())
  end

  def filter_by(query, filter) do
    filter_by(query, filter, @filterable_fields)
  end

  def for_owner_type(owner_type) do
    from fc in FileCollection, where: fc.owner_type == ^owner_type
  end

  def preloads({:files, ef_preloads}, options) do
    query = File.Query.default() |> File.Query.uploaded()
    [files: {query, File.Query.preloads(ef_preloads, options)}]
  end

  def preloads({:memberships, membership_preloads}, options) do
    query =
      FileCollectionMembership.Query.default()
      |> FileCollectionMembership.Query.with_file_status("uploaded")
      |> FileCollectionMembership.Query.paginate(size: 10, number: 1)
      |> FileCollectionMembership.Query.order_by([desc: :sort_index, desc: :inserted_at])

    [memberships: {query, FileCollectionMembership.Query.preloads(membership_preloads, options)}]
  end
end