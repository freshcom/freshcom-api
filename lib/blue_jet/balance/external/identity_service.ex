defmodule BlueJet.Balance.IdentityService do
  @identity_service Application.get_env(:blue_jet, :balance)[:identity_service]

  @callback put_vas_data(map) :: map
  @callback get_account(String.t | map) :: map
  @callback get_user(map, map) :: map

  defdelegate get_account(id_or_struct), to: @identity_service
  defdelegate get_user(identifiers, options), to: @identity_service
  defdelegate put_vas_data(request), to: @identity_service
end