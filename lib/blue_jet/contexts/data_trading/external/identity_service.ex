defmodule BlueJet.DataTrading.IdentityService do
  @identity_service Application.get_env(:blue_jet, :data_trading)[:identity_service]

  @callback put_vas_data(map) :: map

  defdelegate put_vas_data(request), to: @identity_service
end