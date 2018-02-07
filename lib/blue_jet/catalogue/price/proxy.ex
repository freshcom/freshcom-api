defmodule BlueJet.Catalogue.Price.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Catalogue.IdentityService

  def get_account(product) do
    product.account || IdentityService.get_account(product)
  end

  def put_account(product) do
    %{ product | account: get_account(product) }
  end
end