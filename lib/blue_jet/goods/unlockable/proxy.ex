defmodule BlueJet.Goods.Unlockable.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Goods.{IdentityService, FileStorageService}

  def get_account(unlockable) do
    unlockable.account || IdentityService.get_account(unlockable)
  end

  def put_account(unlockable) do
    %{ unlockable | account: get_account(unlockable) }
  end

  def put(unlockable = %{ avatar_id: nil }, {:avatar, nil}, _), do: unlockable

  def put(unlockable, {:avatar, nil}, opts) do
    opts = Map.take(opts, [:account, :account_id])

    avatar = FileStorageService.get_file(%{ id: unlockable.avatar_id }, opts)
    %{ unlockable | avatar: avatar }
  end

  def put(unlockable, {:file_collections, file_collection_path}, opts) do
    preloads = %{ path: file_collection_path, opts: opts }
    opts =
      opts
      |> Map.take([:account, :account_id])
      |> Map.merge(%{ preloads: preloads })

    file_collections = FileStorageService.list_file_collection(%{ filter: %{ owner_id: unlockable.id, owner_type: "Unlockable" } }, opts)
    %{ unlockable | file_collections: file_collections }
  end

  def put(unlockable, _, _), do: unlockable
end