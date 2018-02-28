defmodule BlueJet.Notification.Sms.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Notification.IdentityService

  def get_account(sms) do
    sms.account || IdentityService.get_account(sms)
  end

  def put_account(sms) do
    %{ sms | account: get_account(sms) }
  end

  def put(sms, _, _), do: sms
end