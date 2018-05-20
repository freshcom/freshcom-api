defmodule BlueJet.Crm.PointTransaction.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Crm.IdentityService

  def get_account(point_transaction) do
    point_transaction.account || IdentityService.get_account(point_transaction)
  end

  def put_account(point_transaction) do
    %{ point_transaction | account: get_account(point_transaction) }
  end

  def put(point_transaction, _, _), do: point_transaction
end