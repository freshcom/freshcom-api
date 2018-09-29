defmodule BlueJet.Balance.IdentityService do
  @identity_service Application.get_env(:blue_jet, :balance)[:identity_service]

  @callback get_vad(map) :: map
  @callback get_role(map) :: String.t
  @callback get_account(String.t | map) :: map
  @callback update_account(map, map) :: {:ok, struct} | {:error, %{errors: keyword}}

  @callback get_user(map, map) :: map

  defdelegate get_vad(vas), to: @identity_service
  defdelegate get_role(vad), to: @identity_service
  defdelegate get_account(id_or_struct), to: @identity_service
  defdelegate update_account(fields, map), to: @identity_service
  defdelegate get_user(identifiers, otps), to: @identity_service
end
