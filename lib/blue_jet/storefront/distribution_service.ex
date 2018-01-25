defmodule BlueJet.Storefront.DistributionService do
  alias BlueJet.Distribution.{Fulfillment, FulfillmentLineItem}

  @distribution_service Application.get_env(:blue_jet, :storefront)[:distribution_service]

  @callback create_fulfillment(map) :: Fulfillment.t
  @callback create_fulfillment_line_item(map) :: FulfillmentLineItem.t
  @callback list_fulfillment_line_item(map) :: list

  defdelegate create_fulfillment(map), to: @distribution_service
  defdelegate create_fulfillment_line_item(map), to: @distribution_service
  defdelegate list_fulfillment_line_item(filter), to: @distribution_service
end