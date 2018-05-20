defmodule BlueJet.Notification.Trigger.Proxy do
  use BlueJet, :proxy

  def put(trigger, _, _), do: trigger
end