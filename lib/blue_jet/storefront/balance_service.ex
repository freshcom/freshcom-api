defmodule BlueJet.Storefront.BalanceService do
  @balance_service Application.get_env(:blue_jet, :storefront)[:balance_service]

  @callback list_payment(map, map) :: list(map)
  @callback count_payment(map, map) :: integer

  defdelegate list_payment(fields, opts), to: @balance_service
  defdelegate count_payment(fields, opts), to: @balance_service
end