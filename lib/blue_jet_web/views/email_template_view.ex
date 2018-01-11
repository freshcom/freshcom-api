defmodule BlueJetWeb.EmailTemplateView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :system_label,

    :name,
    :subject, :string,
    :reply_to, :string,
    :to,
    :content_html,
    :content_text,
    :description,

    :inserted_at,
    :updated_at
  ]

  has_many :emails, serializer: BlueJetWeb.EmailView, identifiers: :when_included

  def type do
    "EmailTemplate"
  end
end
