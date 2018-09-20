defmodule BlueJet.Goods.Depositable.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Goods.FileStorageService

  def put(%{avatar_id: nil} = depositable, {:avatar, nil}, _), do: depositable

  def put(depositable, {:avatar, nil}, opts) do
    avatar = FileStorageService.get_file(%{id: depositable.avatar_id}, opts)

    %{depositable | avatar: avatar}
  end

  def put(depositable, {:file_collections, collection_paths}, opts) do
    preload = %{paths: collection_paths, opts: opts}
    opts = Map.put(opts, :preload, preload)
    filter = %{owner_id: depositable.id, owner_type: "Depositable"}

    collections = FileStorageService.list_file_collection(%{filter: filter}, opts)

    %{depositable | file_collections: collections}
  end

  def put(depositable, _, _), do: depositable
end