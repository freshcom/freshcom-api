defmodule BlueJet.Balance.Card.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Balance.IdentityService

  @searchable_fields [
    :code
  ]

  @filterable_fields [
    :payment_id,
    :label
  ]

  def get_account(card) do
    card.account || IdentityService.get_account(card)
  end

  def put_account(card) do
    %{ card | account: get_account(card) }
  end
end