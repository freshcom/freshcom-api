defmodule BlueJet.Notification.SmsTemplate.Proxy do
  use BlueJet, :proxy

  def put(sms_template, _, _), do: sms_template
end
