defmodule BlueJet.Catalogue.Product.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Catalogue.{IdentityService, GoodsService, FileStorageService}

  def get_account(product) do
    product.account || IdentityService.get_account(product)
  end

  def put_account(product) do
    %{ product | account: get_account(product) }
  end

  def get_goods(product = %{ goods_type: "Stockable", goods_id: id }) do
    account = get_account(product)
    GoodsService.get_stockable(%{ id: id }, %{ account: account })
  end

  def get_goods(product = %{ goods_type: "Unlockable", goods_id: id }) do
    account = get_account(product)
    GoodsService.get_unlockable(%{ id: id }, %{ account: account })
  end

  def get_goods(product = %{ goods_type: "Depositable", goods_id: id }) do
    account = get_account(product)
    GoodsService.get_depositable(%{ id: id }, %{ account: account })
  end

  def delete_avatar(product = %{ avatar_id: nil }), do: product

  def delete_avatar(product) do
    account = get_account(product)
    FileStorageService.delete_file(%{ id: product.avatar_id }, %{ account: account })
  end
end