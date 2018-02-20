defmodule BlueJetWeb.EmailView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :status,

    :subject,
    :to,
    :from,
    :reply_to,
    :body_html,
    :body_text,
    :locale,

    :inserted_at,
    :updated_at
  ]

  has_one :trigger, serializer: BlueJetWeb.NotificationTriggerView, identifiers: :always
  has_one :template, serializer: BlueJetWeb.EmailTemplateView, identifiers: :always

  def type do
    "Email"
  end

  def trigger(%{ trigger_id: nil }, _), do: nil
  def trigger(%{ trigger_id: trigger_id, trigger: %Ecto.Association.NotLoaded{} }, _), do: %{ id: trigger_id, type: "FulfillmentPackage" }
  def trigger(%{ trigger: trigger }, _), do: trigger

  def template(%{ template_id: nil }, _), do: nil
  def template(%{ template_id: template_id, template: %Ecto.Association.NotLoaded{} }, _), do: %{ id: template_id, type: "FulfillmentPackage" }
  def template(%{ template: template }, _), do: template
end
