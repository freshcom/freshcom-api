defmodule BlueJet.Notification.Trigger.Query do
  use BlueJet, :query
  use BlueJet.Query.Search, for: [
    :name,
    :event
  ]
  use BlueJet.Query.Filter, for: [
    :id,
    :status,
    :event,
    :action_target,
    :action_type
  ]

  alias BlueJet.Notification.Trigger

  def default() do
    from t in Trigger
  end

  def preloads(_, _) do
    []
  end
end
