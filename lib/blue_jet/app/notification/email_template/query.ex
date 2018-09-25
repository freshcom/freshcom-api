defmodule BlueJet.Notification.EmailTemplate.Query do
  @behaviour BlueJet.Query

  use BlueJet, :query

  alias BlueJet.Notification.EmailTemplate

  def identifiable_fields, do: [:id, :from]
  def filterable_fields, do: [:id, :from]
  def searchable_fields, do: [:name, :subject, :to, :reply_to]

  def default(), do: from(et in EmailTemplate)
  def get_by(q, i), do: filter_by(q, i, identifiable_fields())
  def filter_by(q, f), do: filter_by(q, f, filterable_fields())
  def search(q, k, l, d),
    do: search(q, k, l, d, searchable_fields(), EmailTemplate.translatable_fields())

  def preloads(_, _) do
    []
  end
end
