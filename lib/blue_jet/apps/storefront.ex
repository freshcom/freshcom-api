defmodule BlueJet.Storefront do
  use BlueJet, :context

  def list_order(req), do: list("order", req, __MODULE__)
  def create_order(req), do: create("order", req, __MODULE__)
  def get_order(req), do: get("order", req, __MODULE__)
  def update_order(req), do: update("order", req, __MODULE__)
  def delete_order(req), do: delete("order", req, __MODULE__)

  def create_order_line_item(req), do: create("order_line_item", req, __MODULE__)
  def update_order_line_item(req), do: update("order_line_item", req, __MODULE__)
  def delete_order_line_item(req), do: delete("order_line_item", req, __MODULE__)
end
