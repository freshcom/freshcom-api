defmodule BlueJet.CRM.FileStorageService do
  @moduledoc false

  @file_storage_service Application.get_env(:blue_jet, :crm)[:file_storage_service]

  @callback list_file_collection(map, map) :: list

  defdelegate list_file_collection(fields, opts), to: @file_storage_service
end
