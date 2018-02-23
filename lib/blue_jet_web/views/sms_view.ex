defmodule BlueJetWeb.SmsView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :status,

    :to,
    :body,
    :locale,

    :inserted_at,
    :updated_at
  ]

  has_one :trigger, serializer: BlueJetWeb.NotificationTriggerView, identifiers: :always
  has_one :template, serializer: BlueJetWeb.SmsTemplateView, identifiers: :always

  def type do
    "Sms"
  end

  def trigger(%{ trigger_id: nil }, _), do: nil
  def trigger(%{ trigger_id: trigger_id, trigger: %Ecto.Association.NotLoaded{} }, _), do: %{ id: trigger_id, type: "NotificationTrigger" }
  def trigger(%{ trigger: trigger }, _), do: trigger

  def template(%{ template_id: nil }, _), do: nil
  def template(%{ template_id: template_id, template: %Ecto.Association.NotLoaded{} }, _), do: %{ id: template_id, type: "SmsTemplate" }
  def template(%{ template: template }, _), do: template
end
