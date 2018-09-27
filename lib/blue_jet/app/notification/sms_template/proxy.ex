defmodule BlueJet.Notification.SMSTemplate.Proxy do
  use BlueJet, :proxy

  def put(sms_template, _, _), do: sms_template
end
