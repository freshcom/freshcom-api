defmodule BlueJet.Goods.IdentityData do
  @identity_data Application.get_env(:blue_jet, :goods)[:identity_data]

  @callback get_account(String.t | map) :: map
  @callback get_default_locale(map) :: String.t

  defdelegate get_account(id_or_struct), to: @identity_data
  defdelegate get_default_locale(struct), to: @identity_data
end