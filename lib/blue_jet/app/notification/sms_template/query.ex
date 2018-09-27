defmodule BlueJet.Notification.SMSTemplate.Query do
  @behaviour BlueJet.Query

  use BlueJet, :query

  alias BlueJet.Notification.SMSTemplate

  def identifiable_fields, do: [:id]
  def filterable_fields, do: [:id]
  def searchable_fields, do: [:name, :to]

  def default(), do: from(st in SMSTemplate)
  def get_by(q, i), do: filter_by(q, i, identifiable_fields())
  def filter_by(q, f), do: filter_by(q, f, filterable_fields())
  def search(q, k, l, d),
    do: search(q, k, l, d, searchable_fields(), SMSTemplate.translatable_fields())

  def preloads(_, _) do
    []
  end
end
