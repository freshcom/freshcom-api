defmodule BlueJet.Storefront.CrmService do
  alias BlueJet.Crm.{Customer, PointAccount, PointTransaction}

  @crm_service Application.get_env(:blue_jet, :storefront)[:crm_service]

  @callback get_customer(map, map) :: Customer.t | nil

  @callback get_point_account(String.t, map) :: PointAccount.t | nil
  @callback create_point_transaction(map, map) :: {:ok, PointTransaction.t} | {:error, any}
  @callback update_point_transaction(String.t, map, map) :: {:ok, PointTransaction.t} | {:error, any}
  @callback get_point_transaction(String.t) :: PointTransaction.t | nil

  defdelegate get_customer(fields, opts), to: @crm_service

  defdelegate get_point_account(customer_id, opts), to: @crm_service
  defdelegate create_point_transaction(fields, map), to: @crm_service
  defdelegate update_point_transaction(id, fields, opts), to: @crm_service
  defdelegate get_point_transaction(id), to: @crm_service
end