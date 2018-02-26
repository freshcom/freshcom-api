defmodule BlueJet.Identity.User.Proxy do
  use BlueJet, :proxy

  def put(user, _, _), do: user
end