defmodule BlueJet.Catalogue.ProductCollection.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Catalogue.FileStorageService

  def delete_avatar(%{avatar_id: nil}), do: {:ok, nil}

  def delete_avatar(product_collection) do
    account = get_account(product_collection)
    FileStorageService.delete_file(%{id: product_collection.avatar_id}, %{account: account})
  end

  def put(%{avatar_id: nil} = collection, {:avatar, nil}, _), do: collection

  def put(collection, {:avatar, nil}, opts) do
    avatar = FileStorageService.get_file(%{id: collection.avatar_id}, opts)

    %{collection | avatar: avatar}
  end

  def put(product_collection, _, _), do: product_collection
end
