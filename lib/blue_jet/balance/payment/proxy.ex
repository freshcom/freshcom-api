defmodule BlueJet.Balance.Payment.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Balance.IdentityService

  def get_account(payment) do
    payment.account || IdentityService.get_account(payment)
  end

  def put_account(payment) do
    %{ payment | account: get_account(payment) }
  end
end