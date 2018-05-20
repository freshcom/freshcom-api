defmodule BlueJet.Fulfillment.ReturnPackage.Proxy do
  use BlueJet, :proxy

  def put(package, _, _), do: package
end