defmodule BlueJet.FileStorage.Service do
  @service Application.get_env(:blue_jet, :file_storage)[:service]

  @callback list_file(map, map) :: [File.t]
  @callback count_file(map, map) :: integer
  @callback create_file(map, map) :: {:ok, File.t} | {:error, any}
  @callback get_file(map, map) :: File.t | nil
  @callback update_file(String.t | File.t, map, map) :: {:ok, File.t} | {:error, any}
  @callback delete_file(String.t | File.t, map) :: {:ok, File.t} | {:error, any}
  @callback delete_all_file(map) :: :ok

  @callback list_file_collection(map, map) :: [FileCollection.t]
  @callback count_file_collection(map, map) :: integer
  @callback create_file_collection(map, map) :: {:ok, FileCollection.t} | {:error, any}
  @callback get_file_collection(map, map) :: FileCollection.t | nil
  @callback update_file_collection(String.t | FileCollection.t, map, map) :: {:ok, FileCollection.t} | {:error, any}
  @callback delete_file_collection(String.t | FileCollection.t, map) :: {:ok, FileCollection.t} | {:error, any}
  @callback delete_all_file_collection(map) :: :ok

  @callback delete_file_collection_membership(String.t | FileCollectionMembership.t, map) :: {:ok, FileCollectionMembership.t} | {:error, any}

  defdelegate list_file(params, opts), to: @service
  defdelegate count_file(params \\ %{}, opts), to: @service
  defdelegate create_file(fields, opts), to: @service
  defdelegate get_file(identifiers, opts), to: @service
  defdelegate update_file(id_or_file, fields, opts), to: @service
  defdelegate delete_file(id_or_file, opts), to: @service
  defdelegate delete_all_file(opts), to: @service

  defdelegate list_file_collection(params, opts), to: @service
  defdelegate count_file_collection(params \\ %{}, opts), to: @service
  defdelegate create_file_collection(fields, opts), to: @service
  defdelegate get_file_collection(identifiers, opts), to: @service
  defdelegate update_file_collection(id_or_file_collection, fields, opts), to: @service
  defdelegate delete_file_collection(id_or_file_collection, opts), to: @service
  defdelegate delete_all_file_collection(opts), to: @service

  defdelegate delete_file_collection_membership(id_or_fcm, opts), to: @service
end