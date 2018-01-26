defmodule BlueJet.Catalogue.IdentityService do
  @identity_service Application.get_env(:blue_jet, :catalogue)[:identity_service]

  @callback get_account(String.t | map) :: map

  defdelegate get_account(id_or_struct), to: @identity_service
end