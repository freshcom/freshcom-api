defmodule BlueJet.Notification.Email.Proxy do
  use BlueJet, :proxy

  def put(email, _, _), do: email
end
