defmodule BlueJet.FileStorage.FileCollection.Query do
  @behaviour BlueJet.Query

  use BlueJet, :query

  alias BlueJet.FileStorage.{FileCollection, File, FileCollectionMembership}

  def identifiable_fields, do: [:id, :status]
  def filterable_fields, do: [:id, :status, :label, :owner_id, :owner_type, :content_type]
  def searchable_fields, do: [:id, :name, :content_type, :code]

  def default() do
    from(fc in FileCollection)
  end

  def get_by(q, i), do: filter_by(q, i, identifiable_fields())

  def filter_by(q, f), do: filter_by(q, f, filterable_fields())

  def search(q, k, l, d),
    do: search(q, k, l, d, searchable_fields(), FileCollection.translatable_fields())

  def preloads({:files, ef_preloads}, options) do
    query = File.Query.default() |> File.Query.filter_by(%{status: "uploaded"})
    [files: {query, File.Query.preloads(ef_preloads, options)}]
  end

  def preloads({:memberships, membership_preloads}, options) do
    query =
      FileCollectionMembership.Query.default()
      |> FileCollectionMembership.Query.with_file_status("uploaded")
      |> BlueJet.Query.paginate(size: 10, number: 1)
      |> order_by(desc: :sort_index, desc: :inserted_at)

    [memberships: {query, FileCollectionMembership.Query.preloads(membership_preloads, options)}]
  end
end
