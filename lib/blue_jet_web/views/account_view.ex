defmodule BlueJetWeb.AccountView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :name,
    :default_locale,
    :caption,
    :description,
    :custom_data
  ]

  def type do
    "Account"
  end
end
