defmodule BlueJet.Notification.EmailTemplate.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Notification.IdentityService

  def get_account(email_template) do
    email_template.account || IdentityService.get_account(email_template)
  end

  def put_account(email_template) do
    %{ email_template | account: get_account(email_template) }
  end

  def put(email_template, _, _), do: email_template
end
