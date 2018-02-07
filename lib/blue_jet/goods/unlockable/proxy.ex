defmodule BlueJet.Goods.Unlockable.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Goods.IdentityService

  def get_account(unlockable) do
    unlockable.account || IdentityService.get_account(unlockable)
  end

  def put_account(unlockable) do
    %{ unlockable | account: get_account(unlockable) }
  end
end