defmodule BlueJet.Storefront.FulfillmentService do
  alias BlueJet.Fulfillment.{FulfillmentPackage, FulfillmentItem}

  @fulfillment_service Application.get_env(:blue_jet, :storefront)[:fulfillment_service]

  @callback create_fulfillment_package(map, map) :: {:ok, FulfillmentPackage.t} | {:error, any}
  @callback create_fulfillment_item(map, map) :: {:ok, FulfillmentItem.t} | {:error, any}
  @callback list_fulfillment_item(map, map) :: list

  defdelegate create_fulfillment_package(fields, opts), to: @fulfillment_service
  defdelegate create_fulfillment_item(fields, opts), to: @fulfillment_service
  defdelegate list_fulfillment_item(filter, opts), to: @fulfillment_service
end