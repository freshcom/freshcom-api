defmodule BlueJet.Notification.Trigger.Query do
  @behaviour BlueJet.Query

  use BlueJet, :query

  alias BlueJet.Notification.Trigger

  def identifiable_fields, do: [:id, :status]
  def filterable_fields, do: [:id, :status, :event, :action_target, :action_type]
  def searchable_fields, do: [:name, :event]

  def default(), do: from(t in Trigger)
  def get_by(q, i), do: filter_by(q, i, identifiable_fields())
  def filter_by(q, f), do: filter_by(q, f, filterable_fields())
  def search(q, k, l, d),
    do: search(q, k, l, d, searchable_fields(), [])

  def preloads(_, _) do
    []
  end
end
