defmodule BlueJet.Goods.FileStorageService do
  @file_storage_service Application.get_env(:blue_jet, :goods)[:file_storage_service]

  @callback delete_file(String.t, map) :: File.t | nil
  @callback get_file(map, map) :: File.t | nil
  @callback list_file_collection(map, map) :: list

  defdelegate delete_file(id, opts), to: @file_storage_service
  defdelegate get_file(fields, opts), to: @file_storage_service
  defdelegate list_file_collection(fields, opts), to: @file_storage_service
end