defmodule BlueJet.DataTrading.Policy do
  alias BlueJet.AccessRequest
  alias BlueJet.DataTrading.{IdentityService}

  def authorize(request = %{ role: role }, "create_data_import") when role in ["developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :create)}
  end

  #
  # MARK: Other
  #
  def authorize(request = %{ role: nil }, endpoint) do
    request
    |> IdentityService.put_vas_data()
    |> authorize(endpoint)
  end

  def authorize(_, _) do
    {:error, :access_denied}
  end
end
