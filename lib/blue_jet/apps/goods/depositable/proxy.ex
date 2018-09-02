defmodule BlueJet.Goods.Depositable.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Goods.FileStorageService

  def put(depositable = %{ avatar_id: nil }, {:avatar, nil}, _), do: depositable

  def put(depositable, {:avatar, nil}, opts) do
    opts = Map.take(opts, [:account, :account_id])

    avatar = FileStorageService.get_file(%{ id: depositable.avatar_id }, opts)
    %{ depositable | avatar: avatar }
  end

  def put(depositable, {:file_collections, file_collection_path}, opts) do
    preloads = %{ path: file_collection_path, opts: opts }
    opts =
      opts
      |> Map.take([:account, :account_id])
      |> Map.merge(%{ preloads: preloads })

    file_collections = FileStorageService.list_file_collection(%{ filter: %{ owner_id: depositable.id, owner_type: "Depositable" } }, opts)
    %{ depositable | file_collections: file_collections }
  end

  def put(depositable, _, _), do: depositable
end