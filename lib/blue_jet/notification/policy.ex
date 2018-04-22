defmodule BlueJet.Notification.Policy do
  alias BlueJet.AccessRequest
  alias BlueJet.Notification.IdentityService

  def authorize(request = %{ role: role, account: account, user: user }, "update_trigger") when role in ["developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :update)}
  end

  def authorize(request = %{ role: nil }, endpoint) do
    request
    |> IdentityService.put_vas_data()
    |> authorize(endpoint)
  end

  def authorize(_, _) do
    {:error, :access_denied}
  end
end
