defmodule BlueJet.CRM.PointAccount.Proxy do
  use BlueJet, :proxy

  def put(point_account, _, _), do: point_account
end
