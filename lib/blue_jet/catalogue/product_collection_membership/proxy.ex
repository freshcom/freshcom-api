defmodule BlueJet.Catalogue.ProductCollectionMembership.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Catalogue.IdentityService

  def get_account(membership) do
    membership.account || IdentityService.get_account(membership)
  end

  def put_account(membership) do
    %{ membership | account: get_account(membership) }
  end

  def put(membership, _, _), do: membership
end