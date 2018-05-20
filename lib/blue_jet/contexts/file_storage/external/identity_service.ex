defmodule BlueJet.FileStorage.IdentityService do
  @identity_service Application.get_env(:blue_jet, :file_storage)[:identity_service]

  @callback put_vas_data(map) :: map
  @callback get_account(String.t | map) :: map

  defdelegate get_account(id_or_struct), to: @identity_service
  defdelegate put_vas_data(request), to: @identity_service
end