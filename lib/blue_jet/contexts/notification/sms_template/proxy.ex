defmodule BlueJet.Notification.SmsTemplate.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Notification.IdentityService

  def get_account(sms_template) do
    sms_template.account || IdentityService.get_account(sms_template)
  end

  def put_account(sms_template) do
    %{ sms_template | account: get_account(sms_template) }
  end

  def put(sms_template, _, _), do: sms_template
end
