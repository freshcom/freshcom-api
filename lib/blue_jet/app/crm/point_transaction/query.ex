defmodule BlueJet.CRM.PointTransaction.Query do
  @behaviour BlueJet.Query

  use BlueJet, :query

  alias BlueJet.CRM.{PointTransaction, PointAccount}

  def identifiable_fields, do: [:id, :status, :point_account_id]
  def filterable_fields, do: [:id, :status, :label, :point_account_id, :reason_label]
  def searchable_fields, do: [:name, :caption]

  def default(), do: from(pt in PointTransaction)
  def get_by(q, i), do: filter_by(q, i, identifiable_fields())
  def filter_by(q, f), do: filter_by(q, f, filterable_fields())
  def search(q, k, l, d),
    do: search(q, k, l, d, searchable_fields(), PointTransaction.translatable_fields())

  def preloads({:point_account, point_account_preloads}, options) do
    [
      point_account:
        {PointAccount.Query.default(),
         PointAccount.Query.preloads(point_account_preloads, options)}
    ]
  end

  def preloads(_, _) do
    []
  end

  def for_point_account(query, point_account_id) do
    from(pt in query, where: pt.point_account_id == ^point_account_id)
  end
end
