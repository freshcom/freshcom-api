defmodule BlueJet.Fulfillment.ReturnItem.Proxy do
  use BlueJet, :proxy

  def put(return_item, _, _), do: return_item
end
