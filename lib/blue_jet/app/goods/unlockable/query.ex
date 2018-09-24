defmodule BlueJet.Goods.Unlockable.Query do
  @behaviour BlueJet.Query

  use BlueJet, :query

  alias BlueJet.Goods.Unlockable

  def identifiable_fields, do: [:id, :status]
  def filterable_fields, do: [:id, :status, :label]
  def searchable_fields, do: [:code, :name]

  def default(), do: from s in Unlockable

  def get_by(q, i), do: filter_by(q, i, identifiable_fields())

  def filter_by(q, f), do: filter_by(q, f, filterable_fields())

  def search(q, k, l, d),
    do: search(q, k, l, d, searchable_fields(), Unlockable.translatable_fields())

  def preloads(_, _), do: []
end