defmodule BlueJetWeb.SMSTemplateView do
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

  has_many :smses, serializer: BlueJetWeb.SMSView, identifiers: :when_included

  def type do
    "SMSTemplate"
  end
end
