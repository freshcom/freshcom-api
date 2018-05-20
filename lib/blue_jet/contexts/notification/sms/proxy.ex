defmodule BlueJet.Notification.Sms.Proxy do
  use BlueJet, :proxy

  def put(sms, _, _), do: sms
end