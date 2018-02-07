defmodule BlueJet.Goods.Depositable.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Goods.IdentityService

  def get_account(depositable) do
    depositable.account || IdentityService.get_account(depositable)
  end

  def put_account(depositable) do
    %{ depositable | account: get_account(depositable) }
  end
end