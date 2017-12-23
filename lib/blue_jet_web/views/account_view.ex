defmodule BlueJetWeb.AccountView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :name,
    :default_locale,
    :test_account_id,
    :caption,
    :description,
    :custom_data
  ]

  def type do
    "Account"
  end
end
