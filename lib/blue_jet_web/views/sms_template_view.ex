defmodule BlueJetWeb.SmsTemplateView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :system_label,

    :name,
    :to,
    :body,
    :description,

    :inserted_at,
    :updated_at
  ]

  has_many :smses, serializer: BlueJetWeb.SmsView, identifiers: :when_included

  def type do
    "SmsTemplate"
  end
end
