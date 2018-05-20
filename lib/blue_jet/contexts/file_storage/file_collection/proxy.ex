defmodule BlueJet.FileStorage.FileCollection.Proxy do
  use BlueJet, :proxy

  def put(file_collection, _, _), do: file_collection
end