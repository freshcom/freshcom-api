defmodule BlueJet.Catalogue.Price.Proxy do
  use BlueJet, :proxy

  def put(price, _, _), do: price
end
