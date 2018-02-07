defmodule BlueJet.Goods.Stockable.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Goods.IdentityService

  def get_account(stockable) do
    stockable.account || IdentityService.get_account(stockable)
  end

  def put_account(stockable) do
    %{ stockable | account: get_account(stockable) }
  end
end