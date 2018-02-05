defmodule BlueJet.Catalogue.FileStorageService do

  @file_storage_service Application.get_env(:blue_jet, :catalogue)[:file_storage_service]

  @callback delete_file(String.t, map) :: nil

  defdelegate delete_file(id, opts), to: @file_storage_service
end