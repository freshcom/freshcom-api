defmodule BlueJet.FileStorage.FileCollectionMembership.Proxy do
  use BlueJet, :proxy

  def put(fcm, _, _), do: fcm
end
