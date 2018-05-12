defmodule BlueJet.Crm do
  use BlueJet, :context

  def list_customer(req), do: list("customer", req)
  def create_customer(req), do: create("customer", req)
  def get_customer(req), do: get("customer", req)
  def update_customer(req), do: update("customer", req)
  def delete_customer(req), do: delete("customer", req)

  def list_point_transaction(req), do: list("point_transaction", req)
  def create_point_transaction(req), do: create("point_transaction", req)
  def get_point_transaction(req), do: get("point_transaction", req)
  def update_point_transaction(req), do: update("point_transaction", req)
  def delete_point_transaction(req), do: delete("point_transaction", req)
end
