defmodule BlueJet.Notification.Trigger.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Notification.IdentityService

  def get_account(trigger) do
    trigger.account || IdentityService.get_account(trigger)
  end

  def put_account(trigger) do
    %{ trigger | account: get_account(trigger) }
  end

  def put(trigger, _, _), do: trigger
end