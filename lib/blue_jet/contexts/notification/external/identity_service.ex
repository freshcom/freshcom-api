defmodule BlueJet.Notification.IdentityService do
  @identity_service Application.get_env(:blue_jet, :notification)[:identity_service]

  @callback get_account(String.t() | map) :: map
  @callback put_vas_data(map) :: map

  defdelegate get_account(id_or_struct), to: @identity_service
  defdelegate put_vas_data(request), to: @identity_service
end
