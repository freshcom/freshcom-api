defmodule BlueJet.Catalogue.ProductCollectionMembership.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Catalogue.IdentityService

  def get_account(product_collection) do
    product_collection.account || IdentityService.get_account(product_collection)
  end

  def put_account(product_collection) do
    %{ product_collection | account: get_account(product_collection) }
  end
end