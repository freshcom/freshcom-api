defmodule BlueJet.Notification.Email.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Notification.IdentityService

  def get_account(email) do
    email.account || IdentityService.get_account(email)
  end

  def put_account(email) do
    %{ email | account: get_account(email) }
  end

  def put(email, _, _), do: email
end