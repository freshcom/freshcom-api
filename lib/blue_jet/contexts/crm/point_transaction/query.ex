defmodule BlueJet.Crm.PointTransaction.Query do
  use BlueJet, :query
  use BlueJet.Query.Search, for: [
    :name,
    :caption
  ]
  use BlueJet.Query.Filter, for: [
    :status,
    :label,
    :point_account_id,
    :reason_label,
  ]

  alias BlueJet.Crm.{PointTransaction, PointAccount}

  def default() do
    from(pt in PointTransaction)
  end

  def for_point_account(query, point_account_id) do
    from(pt in query, where: pt.point_account_id == ^point_account_id)
  end

  def preloads({:point_account, point_account_preloads}, options) do
    [point_account: {PointAccount.Query.default(), PointAccount.Query.preloads(point_account_preloads, options)}]
  end

  def preloads(_, _) do
    []
  end
end