defmodule BlueJet.Goods.IdentityService do
  @identity_service Application.get_env(:blue_jet, :goods)[:identity_service]

  @callback get_account(String.t | map) :: map
  @callback get_default_locale(map) :: String.t

  defdelegate get_account(id_or_struct), to: @identity_service
  defdelegate get_default_locale(struct), to: @identity_service
end