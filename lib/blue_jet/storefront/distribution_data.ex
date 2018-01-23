defmodule BlueJet.Storefront.DistributionData do
  alias BlueJet.Distribution.{Fulfillment, FulfillmentLineItem}

  @distribution_data Application.get_env(:blue_jet, :storefront)[:distribution_data]

  @callback create_fulfillment(map) :: Fulfillment.t
  @callback create_fulfillment_line_item(map) :: FulfillmentLineItem.t
  @callback list_fulfillment_line_item(map) :: list

  defdelegate create_fulfillment(map), to: @distribution_data
  defdelegate create_fulfillment_line_item(map), to: @distribution_data
  defdelegate list_fulfillment_line_item(filter), to: @distribution_data
end