defmodule BlueJet.Fulfillment.ReturnItem.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Goods.IdentityService

  def get_account(return_item) do
    return_item.account || IdentityService.get_account(return_item)
  end

  def put_account(return_item) do
    %{ return_item | account: get_account(return_item) }
  end

  def put(return_item, _, _), do: return_item
end