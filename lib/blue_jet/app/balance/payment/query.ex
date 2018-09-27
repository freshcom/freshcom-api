defmodule BlueJet.Balance.Payment.Query do
  use BlueJet, :query

  alias BlueJet.Balance.{Payment, Refund}

  def identifiable_fields, do: [:id, :status]
  def filterable_fields, do: [:id, :status, :target_type, :target_id, :owner_id, :owner_type, :gateway, :method, :label]
  def searchable_fields, do: [:code]

  def default(), do: from p in Payment
  def get_by(q, i), do: filter_by(q, i, identifiable_fields())
  def filter_by(q, f), do: filter_by(q, f, filterable_fields())
  def search(q, k, l, d),
    do: search(q, k, l, d, searchable_fields(), Payment.translatable_fields())

  def preloads({:refunds, refund_preloads}, options) do
    [refunds: {Refund.Query.default(), Refund.Query.preloads(refund_preloads, options)}]
  end
end
