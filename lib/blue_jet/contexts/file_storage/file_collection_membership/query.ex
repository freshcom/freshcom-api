defmodule BlueJet.FileStorage.FileCollectionMembership.Query do
  use BlueJet, :query
  use BlueJet.Query.Filter, for: [
    :id,
    :file_id,
    :collection_id
  ]

  alias BlueJet.FileStorage.{FileCollectionMembership, File}

  def default() do
    from fcm in FileCollectionMembership
  end

  def for_collection(query, collection_id) do
    from fcm in query, where: fcm.collection_id == ^collection_id
  end

  def with_file_status(query, nil) do
    query
  end

  def with_file_status(query, status) do
    from fcm in query,
      join: f in File, on: f.id == fcm.file_id,
      where: f.status == ^status
  end

  def preloads({:file, ef_preloads}, options) do
    query = File.Query.default()
    [file: {query, File.Query.preloads(ef_preloads, options)}]
  end
end