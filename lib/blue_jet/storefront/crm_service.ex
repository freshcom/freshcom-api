defmodule BlueJet.Storefront.CrmService do
  alias BlueJet.Crm.{Customer, PointAccount, PointTransaction}

  @crm_service Application.get_env(:blue_jet, :storefront)[:crm_service]

  @callback get_customer(String.t, map) :: Customer.t
  @callback get_customer_by_user_id(String.t, map) :: Customer.t
  @callback get_point_account(String.t, map) :: PointAccount.t
  @callback create_point_transaction(map, map) :: PointTransaction.t
  @callback update_point_transaction(String.t, map, map) :: PointTransaction.t
  @callback get_point_transaction(String.t) :: PointTransaction.t

  defdelegate get_customer(id, opts), to: @crm_service
  defdelegate get_customer_by_user_id(id, opts), to: @crm_service
  defdelegate get_point_account(customer_id, opts), to: @crm_service
  defdelegate create_point_transaction(fields, map), to: @crm_service
  defdelegate update_point_transaction(id, fields, opts), to: @crm_service
  defdelegate get_point_transaction(id), to: @crm_service
end