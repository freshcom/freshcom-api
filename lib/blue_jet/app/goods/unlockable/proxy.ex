defmodule BlueJet.Goods.Unlockable.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Goods.FileStorageService

  def put(%{avatar_id: nil} = unlockable, {:avatar, nil}, _), do: unlockable

  def put(unlockable, {:avatar, nil}, opts) do
    avatar = FileStorageService.get_file(%{id: unlockable.avatar_id}, opts)

    %{unlockable | avatar: avatar}
  end

  def put(unlockable = %{file_id: file_id}, {:file, nil}, opts) when not is_nil(file_id) do
    file = FileStorageService.get_file(%{id: file_id}, opts)

    %{unlockable | file: file}
  end

  def put(unlockable, {:file_collections, collection_paths}, opts) do
    preload = %{paths: collection_paths, opts: opts}
    opts = Map.put(opts, :preload, preload)
    filter = %{owner_id: unlockable.id, owner_type: "Unlockable"}

    collections = FileStorageService.list_file_collection(%{filter: filter}, opts)

    %{unlockable | file_collections: collections}
  end

  def put(unlockable, _, _), do: unlockable
end