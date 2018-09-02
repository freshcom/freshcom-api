defmodule BlueJet.Notification.EmailTemplate.Proxy do
  use BlueJet, :proxy

  def put(email_template, _, _), do: email_template
end
