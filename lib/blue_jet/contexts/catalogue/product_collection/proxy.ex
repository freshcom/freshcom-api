defmodule BlueJet.Catalogue.ProductCollection.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Catalogue.FileStorageService

  def delete_avatar(product_collection = %{ avatar_id: nil }), do: product_collection

  def delete_avatar(product_collection) do
    account = get_account(product_collection)
    FileStorageService.delete_file(%{ id: product_collection.avatar_id }, %{ account: account })
  end

  def put(product_collection, _, _), do: product_collection
end