defmodule BlueJet.Distribution.FulfillmentLineItem.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Goods.IdentityService

  def get_account(fli) do
    fli.account || IdentityService.get_account(fli)
  end

  def put_account(fli) do
    %{ fli | account: get_account(fli) }
  end

  def put(fli, _, _), do: fli
end