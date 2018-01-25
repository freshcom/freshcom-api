defmodule BlueJet.Storefront.DistributionService do
  alias BlueJet.Distribution.{Fulfillment, FulfillmentLineItem}

  @distribution_service Application.get_env(:blue_jet, :storefront)[:distribution_service]

  @callback create_fulfillment(map, map) :: {:ok, Fulfillment.t} | {:error, any}
  @callback create_fulfillment_line_item(map, map) :: {:ok, FulfillmentLineItem.t} | {:error, any}
  @callback list_fulfillment_line_item(map) :: list

  defdelegate create_fulfillment(fields, opts), to: @distribution_service
  defdelegate create_fulfillment_line_item(fields, opts), to: @distribution_service
  defdelegate list_fulfillment_line_item(filter), to: @distribution_service
end