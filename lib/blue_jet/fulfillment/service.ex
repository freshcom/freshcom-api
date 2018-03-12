defmodule BlueJet.Fulfillment.Service do
  @service Application.get_env(:blue_jet, :fulfillment)[:service]

  @callback list_fulfillment_package(map, map) :: [FulfillmentPackage.t]
  @callback count_fulfillment_package(map, map) :: integer
  @callback delete_fulfillment_package(String.t | FulfillmentPackage.t, map) :: {:ok, FulfillmentPackage.t} | {:error, any}
  @callback delete_all_fulfillment_package(map) :: :ok

  @callback list_fulfillment_item(map, map) :: [FulfillmentItem.t]
  @callback count_fulfillment_item(map, map) :: integer
  @callback create_fulfillment_item(map, map) :: {:ok, FulfillmentItem.t} | {:error, any}
  @callback update_fulfillment_item(String.t | FulfillmentItem.t, map, map) :: {:ok, FulfillmentItem.t} | {:error, any}
  @callback delete_fulfillment_item(String.t | FulfillmentItem.t, map) :: {:ok, FulfillmentItem.t} | {:error, any}

  @callback list_return_package(map, map) :: [ReturnPackage.t]
  @callback count_return_package(map, map) :: integer

  @callback list_unlock(map, map) :: [Unlock.t]
  @callback count_unlock(map, map) :: integer
  @callback create_unlock(map, map) :: {:ok, Unlock.t} | {:error, any}
  @callback get_unlock(map, map) :: Unlock.t | nil
  @callback delete_unlock(String.t | Unlock.t, map) :: {:ok, Unlock.t} | {:error, any}

  defdelegate list_fulfillment_package(params, opts), to: @service
  defdelegate count_fulfillment_package(params \\ %{}, opts), to: @service
  defdelegate delete_all_fulfillment_package(opts), to: @service

  defdelegate list_fulfillment_item(params, opts), to: @service
  defdelegate count_fulfillment_item(params \\ %{}, opts), to: @service
  defdelegate create_fulfillment_item(fields, opts), to: @service
  defdelegate update_fulfillment_item(id_or_fulfillment_item, fields, opts), to: @service
  defdelegate delete_fulfillment_item(id_or_fulfillment_item, opts), to: @service

  defdelegate list_return_package(params, opts), to: @service
  defdelegate count_return_package(params \\ %{}, opts), to: @service

  defdelegate list_unlock(params, opts), to: @service
  defdelegate count_unlock(params \\ %{}, opts), to: @service
  defdelegate create_unlock(fields, opts), to: @service
  defdelegate get_unlock(identifiers, opts), to: @service
  defdelegate delete_unlock(id_or_unlock, opts), to: @service
end