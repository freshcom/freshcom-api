defmodule BlueJetWeb.NotificationTriggerView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :name,
    :status,
    :event,
    :action_type,
    :action_target,
    :description,
    :updated_at,
    :inserted_at
  ]

  def type do
    "NotificationTrigger"
  end

  def action_type(struct, _) do
    Inflex.camelize(struct.action_type, :lower)
  end
end
