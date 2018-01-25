defmodule BlueJet.Storefront.BalanceService do
  @balance_service Application.get_env(:blue_jet, :storefront)[:balance_service]

  @callback list_payment_for_target(String.t, String.t) :: list(map)

  defdelegate list_payment_for_target(target_type, target_id), to: @balance_service
end