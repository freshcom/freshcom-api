defmodule BlueJet.Goods.Stockable.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Goods.FileStorageService

  def put(stockable = %{ avatar_id: nil }, {:avatar, nil}, _), do: stockable

  def put(stockable, {:avatar, nil}, opts) do
    opts = Map.take(opts, [:account, :account_id])

    avatar = FileStorageService.get_file(%{ id: stockable.avatar_id }, opts)
    %{ stockable | avatar: avatar }
  end

  def put(stockable, {:file_collections, file_collection_path}, opts) do
    preloads = %{ path: file_collection_path, opts: opts }
    opts =
      opts
      |> Map.take([:account, :account_id])
      |> Map.merge(%{ preloads: preloads })

    file_collections = FileStorageService.list_file_collection(%{ filter: %{ owner_id: stockable.id, owner_type: "Stockable" } }, opts)
    %{ stockable | file_collections: file_collections }
  end

  def put(stockable, _, _), do: stockable
end