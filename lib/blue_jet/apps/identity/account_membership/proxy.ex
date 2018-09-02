defmodule BlueJet.Identity.AccountMembership.Proxy do
  use BlueJet, :proxy

  def put(am, _, _), do: am
end
