defmodule BlueJet.Fulfillment do
  use BlueJet, :context

  def list_fulfillment_package(req), do: list("fulfillment_package", req, __MODULE__)
  def get_fulfillment_package(req), do: get("fulfillment_package", req, __MODULE__)
  def delete_fulfillment_package(req), do: delete("fulfillment_package", req, __MODULE__)

  def list_fulfillment_item(req), do: list("fulfillment_item", req, __MODULE__)
  def create_fulfillment_item(req), do: create("fulfillment_item", req, __MODULE__)
  def update_fulfillment_item(req), do: update("fulfillment_item", req, __MODULE__)

  def list_return_package(req), do: list("return_package", req, __MODULE__)

  def create_return_item(req), do: create("return_item", req, __MODULE__)

  def list_unlock(req), do: list("unlock", req, __MODULE__)
  def create_unlock(req), do: create("unlock", req, __MODULE__)
  def get_unlock(req), do: get("unlock", req, __MODULE__)
  def delete_unlock(req), do: delete("unlock", req, __MODULE__)
end