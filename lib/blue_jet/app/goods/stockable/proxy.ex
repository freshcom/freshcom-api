defmodule BlueJet.Goods.Stockable.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Goods.FileStorageService

  def put(%{avatar_id: nil} = stockable, {:avatar, nil}, _), do: stockable

  def put(stockable, {:avatar, nil}, opts) do
    avatar = FileStorageService.get_file(%{id: stockable.avatar_id}, opts)

    %{stockable | avatar: avatar}
  end

  def put(stockable, {:file_collections, collection_paths}, opts) do
    preload = %{paths: collection_paths, opts: opts}
    opts = Map.put(opts, :preload, preload)
    filter = %{owner_id: stockable.id, owner_type: "Stockable"}

    collections = FileStorageService.list_file_collection(%{filter: filter}, opts)

    %{stockable | file_collections: collections}
  end

  def put(stockable, _, _), do: stockable
end