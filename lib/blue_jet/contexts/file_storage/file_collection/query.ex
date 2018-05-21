defmodule BlueJet.FileStorage.FileCollection.Query do
  use BlueJet, :query
  use BlueJet.Query.Search, for: [
    :name,
    :content_type,
    :code,
    :id
  ]
  use BlueJet.Query.Filter, for: [
    :id,
    :status,
    :label,
    :owner_id,
    :owner_type,
    :content_type
  ]

  alias BlueJet.FileStorage.{FileCollection, File, FileCollectionMembership}

  def default() do
    from fc in FileCollection
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
      |> BlueJet.Query.paginate(size: 10, number: 1)
      |> order_by([desc: :sort_index, desc: :inserted_at])

    [memberships: {query, FileCollectionMembership.Query.preloads(membership_preloads, options)}]
  end
end