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

  def list_product_collection(req), do: default(req, :list, :product_collection, Policy, Service)
  def create_product_collection(req), do: default(req, :create, :product_collection, Policy, Service)
  def get_product_collection(req), do: default(req, :get, :product_collection, Policy, Service)
  def update_product_collection(req), do: default(req, :update, :product_collection, Policy, Service)
  def delete_product_collection(req), do: default(req, :delete, :product_collection, Policy, Service)

  def list_product_collection_membership(req), do: default(req, :list, :product_collection_membership, Policy, Service)
  def create_product_collection_membership(req), do: default(req, :create, :product_collection_membership, Policy, Service)
  def get_product_collection_membership(req), do: default(req, :get, :product_collection_membership, Policy, Service)
  def update_product_collection_membership(req), do: default(req, :update, :product_collection_membership, Policy, Service)
  def delete_product_collection_membership(req), do: default(req, :delete, :product_collection_membership, Policy, Service)
end
