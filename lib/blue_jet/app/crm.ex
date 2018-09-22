defmodule BlueJet.Crm do
  use BlueJet, :context

  alias BlueJet.Crm.{Policy, Service}

  def list_customer(req), do: default(req, :list, :customer, Policy, Service)
  def create_customer(req), do: default(req, :create, :customer, Policy, Service)
  def get_customer(req), do: default(req, :get, :customer, Policy, Service)
  def update_customer(req), do: default(req, :update, :customer, Policy, Service)
  def delete_customer(req), do: default(req, :delete, :customer, Policy, Service)

  def list_point_transaction(req), do: default(req, :list, :point_transaction, Policy, Service)
  def create_point_transaction(req), do: default(req, :create, :point_transaction, Policy, Service)
  def get_point_transaction(req), do: default(req, :get, :point_transaction, Policy, Service)
  def update_point_transaction(req), do: default(req, :update, :point_transaction, Policy, Service)
  def delete_point_transaction(req), do: default(req, :delete, :point_transaction, Policy, Service)
end
