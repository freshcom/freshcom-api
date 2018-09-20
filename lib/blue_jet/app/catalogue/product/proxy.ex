defmodule BlueJet.Catalogue.Product.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Catalogue.{GoodsService, FileStorageService}

  def get_goods(%{goods_type: "Stockable", goods_id: id} = product) do
    account = get_account(product)
    GoodsService.get_stockable(%{id: id}, %{account: account})
  end

  def get_goods(%{goods_type: "Unlockable", goods_id: id} = product) do
    account = get_account(product)
    GoodsService.get_unlockable(%{id: id}, %{account: account})
  end

  def get_goods(%{goods_type: "Depositable", goods_id: id} = product) do
    account = get_account(product)
    GoodsService.get_depositable(%{id: id}, %{account: account})
  end

  def get_goods(_), do: nil

  def delete_avatar(%{avatar_id: nil}), do: {:ok, nil}

  def delete_avatar(product) do
    account = get_account(product)
    FileStorageService.delete_file(%{id: product.avatar_id}, %{account: account})
  end

  def put(%{avatar_id: nil} = product, {:avatar, nil}, _), do: product

  def put(product, {:avatar, nil}, opts) do
    avatar = FileStorageService.get_file(%{id: product.avatar_id}, opts)

    %{product | avatar: avatar}
  end

  def put(product, {:file_collections, collection_paths}, opts) do
    preload = %{paths: collection_paths, opts: opts}
    opts = Map.put(opts, :preload, preload)
    filter = %{owner_id: product.id, owner_type: "Product"}

    collections = FileStorageService.list_file_collection(%{filter: filter}, opts)

    %{product | file_collections: collections}
  end

  def put(product, _, _), do: product
end
