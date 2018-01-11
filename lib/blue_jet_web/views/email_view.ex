defmodule BlueJetWeb.EmailView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :status,

    :subject,
    :to,
    :from,
    :reply_to,
    :content_html,
    :content_text,
    :locale,

    :inserted_at,
    :updated_at
  ]

  has_one :recipient, serializer: BlueJetWeb.UserView, identifiers: :always
  has_one :trigger, serializer: BlueJetWeb.NotificationTriggerView, identifiers: :always
  has_one :template, serializer: BlueJetWeb.EmailTemplateView, identifiers: :always

  def type do
    "Email"
  end
end
