defmodule BlueJet.Notification.Sms.Query do
  @behaviour BlueJet.Query

  use BlueJet, :query

  alias BlueJet.Notification.Sms

  def identifiable_fields, do: [:id, :status]
  def filterable_fields, do: [:id, :status, :to]
  def searchable_fields, do: [:to, :body]

  def default(), do: from(s in Sms)
  def get_by(q, i), do: filter_by(q, i, identifiable_fields())
  def filter_by(q, f), do: filter_by(q, f, filterable_fields())
  def search(q, k, l, d),
    do: search(q, k, l, d, searchable_fields(), [])

  def preloads(_, _) do
    []
  end
end
