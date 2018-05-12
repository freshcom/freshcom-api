defmodule BlueJet.Fulfillment do
  use BlueJet, :context

  def list_fulfillment_package(req), do: list("fulfillment_package", req)
  def get_fulfillment_package(req), do: get("fulfillment_package", req)
  def delete_fulfillment_package(req), do: delete("fulfillment_package", req)

  def list_fulfillment_item(req), do: list("fulfillment_item", req)
  def create_fulfillment_item(req), do: create("fulfillment_item", req)
  def update_fulfillment_item(req), do: update("fulfillment_item", req)

  def list_return_package(req), do: list("return_package", req)

  def create_return_item(req), do: create("return_item", req)

  def list_unlock(req), do: list("unlock", req)
  def create_unlock(req), do: create("unlock", req)
  def get_unlock(req), do: get("unlock", req)
  def delete_unlock(req), do: delete("unlock", req)
end