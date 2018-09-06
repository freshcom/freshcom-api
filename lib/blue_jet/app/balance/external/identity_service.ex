defmodule BlueJet.Balance.IdentityService do
  @identity_service Application.get_env(:blue_jet, :balance)[:identity_service]

  @callback put_vas_data(map) :: map
  @callback get_account(String.t() | map) :: map
  @callback update_account(map, map, map) :: map

  @callback get_user(map, map) :: map

  defdelegate put_vas_data(request), to: @identity_service
  defdelegate get_account(id_or_struct), to: @identity_service
  defdelegate update_account(id_or_struct, fields, opts \\ %{}), to: @identity_service
  defdelegate get_user(identifiers, options), to: @identity_service
end
