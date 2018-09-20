defmodule BlueJet.Catalogue.FileStorageService do
  @file_storage_service Application.get_env(:blue_jet, :catalogue)[:file_storage_service]

  @callback delete_file(String.t(), map) :: nil
  @callback list_file_collection(map, map) :: list
  @callback get_file(map, map) :: map

  defdelegate delete_file(id, opts), to: @file_storage_service
  defdelegate list_file_collection(fields, opts), to: @file_storage_service
  defdelegate get_file(identifiers, opts), to: @file_storage_service
end
