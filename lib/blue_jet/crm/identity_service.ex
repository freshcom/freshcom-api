defmodule BlueJet.Crm.IdentityService do
  alias BlueJet.Identity.User

  @identity_service Application.get_env(:blue_jet, :crm)[:identity_service]

  @callback get_account(String.t | map) :: map
  @callback create_user(map) :: User.t

  defdelegate get_account(id_or_struct), to: @identity_service
  defdelegate create_user(fields), to: @identity_service
end