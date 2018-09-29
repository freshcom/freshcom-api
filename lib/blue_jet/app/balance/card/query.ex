defmodule BlueJet.Balance.Card.Query do
  @behaviour BlueJet.Query

  use BlueJet, :query

  alias BlueJet.Balance.Card

  def identifiable_fields, do: [:id, :status, :owner_id, :owner_type]
  def filterable_fields, do: [:id, :status, :name, :label, :last_four_digit, :owner_id, :owner_type, :primary]
  def searchable_fields, do: []

  def default(), do: from(c in Card)
  def get_by(q, i), do: filter_by(q, i, identifiable_fields())
  def filter_by(q, f), do: filter_by(q, f, filterable_fields())

  def search(q, k, l, d),
    do: search(q, k, l, d, searchable_fields(), Card.translatable_fields())
end
