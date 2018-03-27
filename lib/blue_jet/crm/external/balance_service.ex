defmodule BlueJet.Crm.BalanceService do
  @balance_service Application.get_env(:blue_jet, :crm)[:balance_service]

  @callback list_card(map, map) :: list

  defdelegate list_card(fields, opts), to: @balance_service
end