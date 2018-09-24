defmodule BlueJet.DataTrading.CRMService do
  alias BlueJet.CRM.Customer

  @crm_service Application.get_env(:blue_jet, :data_trading)[:crm_service]

  @callback get_customer(map, map) :: Customer.t() | nil
  @callback create_customer(map, map) :: {:ok, Customer.t()} | {:error, any}
  @callback update_customer(String.t(), map, map) :: {:ok, Customer.t()} | {:error, any}

  defdelegate get_customer(identifiers, opts), to: @crm_service
  defdelegate create_customer(fields, opts), to: @crm_service
  defdelegate update_customer(id, fields, opts), to: @crm_service
end
