defmodule BlueJet.FileStorage.FileCollection.Proxy do
  use BlueJet, :proxy

  alias BlueJet.FileStorage.IdentityService

  def get_account(file_collection) do
    file_collection.account || IdentityService.get_account(file_collection)
  end

  def put(file_collection, _, _), do: file_collection
end