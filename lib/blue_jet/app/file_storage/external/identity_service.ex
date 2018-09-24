defmodule BlueJet.FileStorage.IdentityService do
  @moduledoc false

  @identity_service Application.get_env(:blue_jet, :file_storage)[:identity_service]

  @callback get_vad(map) :: map
  @callback get_role(map) :: String.t
  @callback get_account(String.t | map) :: map

  defdelegate get_vad(vas), to: @identity_service
  defdelegate get_role(vad), to: @identity_service

  defdelegate get_account(id_or_struct), to: @identity_service
end