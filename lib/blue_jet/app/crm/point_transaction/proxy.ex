defmodule BlueJet.CRM.PointTransaction.Proxy do
  use BlueJet, :proxy

  def put(point_transaction, _, _), do: point_transaction
end
