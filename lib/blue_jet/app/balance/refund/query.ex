defmodule BlueJet.Balance.Refund.Query do
  use BlueJet, :query

  alias BlueJet.Balance.Refund

  def identifiable_fields, do: [:id, :status]

  def filterable_fields,
    do: [
      :status,
      :gateway,
      :processor,
      :method,
      :label,
      :owner_id,
      :owner_type,
      :target_id,
      :target_type
    ]

  def searchable_fields, do: [:code]

  def default(), do: from(s in Refund)
  def get_by(q, i), do: filter_by(q, i, identifiable_fields())
  def filter_by(q, f), do: filter_by(q, f, filterable_fields())

  def search(q, k, l, d),
    do: search(q, k, l, d, searchable_fields(), Refund.translatable_fields())
end
