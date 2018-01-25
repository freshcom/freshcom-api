defmodule BlueJet.Catalogue.FileStorageService do

  @file_storage_service Application.get_env(:blue_jet, :catalogue)[:file_storage_service]

  @callback delete_external_file(String.t) :: nil

  defdelegate delete_external_file(id), to: @file_storage_service
end