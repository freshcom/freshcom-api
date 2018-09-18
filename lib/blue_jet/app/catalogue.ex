defmodule BlueJet.Catalogue do
  use BlueJet, :context

  alias BlueJet.Catalogue.{Policy, Service}

  def list_product(req), do: default(req, :list, :product, Policy, Service)
  def create_product(req), do: default(req, :create, :product, Policy, Service)
  def get_product(req), do: default(req, :get, :product, Policy, Service)
  def update_product(req), do: default(req, :update, :product, Policy, Service)
  def delete_product(req), do: default(req, :delete, :product, Policy, Service)

  def list_price(req), do: default(req, :list, :price, Policy, Service)
  def create_price(req), do: default(req, :create, :price, Policy, Service)
  def get_price(req), do: default(req, :get, :price, Policy, Service)
  def update_price(req), do: default(req, :update, :price, Policy, Service)
  def delete_price(req), do: default(req, :delete, :price, Policy, Service)

  def list_product_collection(req), do: list("product_collection", req, __MODULE__)
  def create_product_collection(req), do: create("product_collection", req, __MODULE__)
  def get_product_collection(req), do: get("product_collection", req, __MODULE__)
  def update_product_collection(req), do: update("product_collection", req, __MODULE__)
  def delete_product_collection(req), do: delete("product_collection", req, __MODULE__)

  def list_product_collection_membership(req), do: list("product_collection_membership", req, __MODULE__)
  def create_product_collection_membership(req), do: create("product_collection_membership", req, __MODULE__)
  def get_product_collection_membership(req), do: get("product_collection_membership", req, __MODULE__)
  def update_product_collection_membership(req), do: update("product_collection_membership", req, __MODULE__)
  def delete_product_collection_membership(req), do: delete("product_collection_membership", req, __MODULE__)
end
