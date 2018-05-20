defmodule BlueJet.Fulfillment.FulfillmentItem.Proxy do
  use BlueJet, :proxy

  def put(fulfillment_item, _, _), do: fulfillment_item
end