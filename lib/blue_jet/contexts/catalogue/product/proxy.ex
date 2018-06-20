defmodule BlueJet.Catalogue.Product.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Catalogue.{GoodsService, FileStorageService}

  def get_goods(product = %{goods_type: "Stockable", goods_id: id}) do
    account = get_account(product)
    GoodsService.get_stockable(%{id: id}, %{account: account})
  end

  def get_goods(product = %{goods_type: "Unlockable", goods_id: id}) do
    account = get_account(product)
    GoodsService.get_unlockable(%{id: id}, %{account: account})
  end

  def get_goods(product = %{goods_type: "Depositable", goods_id: id}) do
    account = get_account(product)
    GoodsService.get_depositable(%{id: id}, %{account: account})
  end

  def get_goods(_), do: nil

  def delete_avatar(%{avatar_id: nil}), do: {:ok, nil}

  def delete_avatar(product) do
    account = get_account(product)
    FileStorageService.delete_file(%{id: product.avatar_id}, %{account: account})
  end

  def put(product, {:file_collections, file_collection_path}, opts) do
    preloads = %{path: file_collection_path, opts: opts}

    opts =
      opts
      |> Map.take([:account, :account_id])
      |> Map.merge(%{preloads: preloads})

    file_collections =
      FileStorageService.list_file_collection(
        %{filter: %{owner_id: product.id, owner_type: "Product"}},
        opts
      )

    %{product | file_collections: file_collections}
  end

  def put(product, _, _), do: product
end
