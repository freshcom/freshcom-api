defmodule BlueJet.Catalogue do
  use BlueJet, :context

  def list_product(req), do: list("product", req)
  def create_product(req), do: create("product", req)
  def get_product(req), do: get("product", req)
  def update_product(req), do: update("product", req)
  def delete_product(req), do: delete("product", req)

  def list_product_collection(req), do: list("product_collection", req)
  def create_product_collection(req), do: create("product_collection", req)
  def get_product_collection(req), do: get("product_collection", req)
  def update_product_collection(req), do: update("product_collection", req)
  def delete_product_collection(req), do: delete("product_collection", req)

  def list_product_collection_membership(req), do: list("product_collection_membership", req)
  def create_product_collection_membership(req), do: create("product_collection_membership", req)
  def get_product_collection_membership(req), do: get("product_collection_membership", req)
  def update_product_collection_membership(req), do: update("product_collection_membership", req)
  def delete_product_collection_membership(req), do: delete("product_collection_membership", req)

  def list_price(req), do: list("price", req)
  def create_price(req), do: create("price", req)
  def get_price(req), do: get("price", req)
  def update_price(req), do: update("price", req)
  def delete_price(req), do: delete("price", req)
end
