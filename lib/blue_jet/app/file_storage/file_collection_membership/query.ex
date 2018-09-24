defmodule BlueJet.FileStorage.FileCollectionMembership.Query do
  @behaviour BlueJet.Query

  use BlueJet, :query

  def identifiable_fields, do: [:id]
  def filterable_fields, do: [:id, :collection_id, :file_id]
  def searchable_fields, do: []

  alias BlueJet.FileStorage.{FileCollectionMembership, File}

  def default() do
    from(fcm in FileCollectionMembership)
  end

  def get_by(q, i), do: filter_by(q, i, identifiable_fields())

  def filter_by(q, f), do: filter_by(q, f, filterable_fields())

  def search(q, k, l, d),
    do: search(q, k, l, d, searchable_fields(), [])

  def preloads({:files, ef_preloads}, options) do
    query = File.Query.default() |> File.Query.filter_by(%{status: "uploaded"})
    [files: {query, File.Query.preloads(ef_preloads, options)}]
  end

  def preloads({:file, ef_preloads}, options) do
    query = File.Query.default()
    [file: {query, File.Query.preloads(ef_preloads, options)}]
  end

  def for_collection(query, collection_id) do
    from(fcm in query, where: fcm.collection_id == ^collection_id)
  end

  def with_file_status(query, nil) do
    query
  end

  def with_file_status(query, status) do
    from(fcm in query, join: f in File, on: f.id == fcm.file_id, where: f.status == ^status)
  end
end
