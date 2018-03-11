defmodule BlueJet.DataTrading.Service do
  @service Application.get_env(:blue_jet, :data_trading)[:service]

  @callback create_data_import(map, map) :: {:ok, DataImport.t} | {:error, any}

  defdelegate create_data_import(fields, opts), to: @service
end