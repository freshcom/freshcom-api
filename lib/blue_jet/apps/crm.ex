defmodule BlueJet.Crm do
  use BlueJet, :context

  def list_customer(req), do: list("customer", req, __MODULE__)
  def create_customer(req), do: create("customer", req, __MODULE__)
  def get_customer(req), do: get("customer", req, __MODULE__)
  def update_customer(req), do: update("customer", req, __MODULE__)
  def delete_customer(req), do: delete("customer", req, __MODULE__)

  def list_point_transaction(req), do: list("point_transaction", req, __MODULE__)
  def create_point_transaction(req), do: create("point_transaction", req, __MODULE__)
  def get_point_transaction(req), do: get("point_transaction", req, __MODULE__)
  def update_point_transaction(req), do: update("point_transaction", req, __MODULE__)
  def delete_point_transaction(req), do: delete("point_transaction", req, __MODULE__)
end
