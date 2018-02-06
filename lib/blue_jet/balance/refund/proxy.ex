defmodule BlueJet.Balance.Refund.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Balance.IdentityService

  def get_account(refund) do
    refund.account || IdentityService.get_account(refund)
  end

  def put_account(refund) do
    %{ refund | account: get_account(refund) }
  end
end