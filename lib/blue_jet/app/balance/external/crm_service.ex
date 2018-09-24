defmodule BlueJet.Balance.CRMService do
  alias BlueJet.CRM.Customer

  @crm_service Application.get_env(:blue_jet, :balance)[:crm_service]

  @callback get_customer(map, map) :: Customer.t() | nil
  @callback update_customer(Customer.t(), map, map) :: {:ok, Customer.t()} | {:error, any}

  defdelegate get_customer(identifiers, opts), to: @crm_service
  defdelegate update_customer(customer, fields, opts), to: @crm_service
end
