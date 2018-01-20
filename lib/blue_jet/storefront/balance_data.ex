defmodule BlueJet.Storefront.BalanceData do
  @balance_data Application.get_env(:blue_jet, :storefront)[:balance_data]

  @callback list_payment_for_target(String.t, String.t) :: list(map)

  defdelegate list_payment_for_target(target_type, target_id), to: @balance_data
end