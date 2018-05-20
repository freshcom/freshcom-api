defmodule BlueJet.Catalogue.ProductCollectionMembership.Proxy do
  use BlueJet, :proxy

  def put(membership, _, _), do: membership
end