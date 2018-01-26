defmodule BlueJet.Storefront.BalanceService do
  @balance_service Application.get_env(:blue_jet, :storefront)[:balance_service]

  @callback list_payment(map, map) :: list(map)

  defdelegate list_payment(filter, opts), to: @balance_service
end