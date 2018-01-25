defmodule BlueJet.Authorization do
  alias BlueJet.AccessRequest

  @authorization Application.get_env(:blue_jet, :authorization)

  @callback authorize_request(AccessRequest.t, String.t) :: {:ok, AccessRequest.t} | {:error, atom}

  defdelegate authorize_request(request, endpoint), to: @authorization
end