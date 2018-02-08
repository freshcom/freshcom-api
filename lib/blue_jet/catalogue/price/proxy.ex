defmodule BlueJet.Catalogue.Price.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Catalogue.IdentityService

  def get_account(price) do
    price.account || IdentityService.get_account(price)
  end

  def put_account(price) do
    %{ price | account: get_account(price) }
  end

  def put(price, _, _), do: price
end