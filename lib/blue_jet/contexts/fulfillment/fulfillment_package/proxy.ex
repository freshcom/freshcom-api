defmodule BlueJet.Fulfillment.FulfillmentPackage.Proxy do
  use BlueJet, :proxy

  def put(package, _, _), do: package
end
