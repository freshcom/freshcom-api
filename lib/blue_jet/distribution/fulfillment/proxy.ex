defmodule BlueJet.Distribution.Fulfillment.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Goods.IdentityService

  def get_account(fulfillment) do
    fulfillment.account || IdentityService.get_account(fulfillment)
  end

  def put_account(fulfillment) do
    %{ fulfillment | account: get_account(fulfillment) }
  end

  def put(fulfillment, _, _), do: fulfillment
end