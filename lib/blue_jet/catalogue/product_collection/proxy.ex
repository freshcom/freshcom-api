defmodule BlueJet.Catalogue.ProductCollection.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Catalogue.{IdentityService, FileStorageService}

  def get_account(product_collection) do
    product_collection.account || IdentityService.get_account(product_collection)
  end

  def put_account(product_collection) do
    %{ product_collection | account: get_account(product_collection) }
  end

  def delete_avatar(product_collection = %{ avatar_id: nil }), do: product_collection

  def delete_avatar(product_collection) do
    account = get_account(product_collection)
    FileStorageService.delete_file(%{ id: product_collection.avatar_id }, %{ account: account })
  end
end