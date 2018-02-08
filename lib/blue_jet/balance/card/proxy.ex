defmodule BlueJet.Balance.Card.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Balance.IdentityService

  def get_account(card) do
    card.account || IdentityService.get_account(card)
  end

  def put_account(card) do
    %{ card | account: get_account(card) }
  end
end