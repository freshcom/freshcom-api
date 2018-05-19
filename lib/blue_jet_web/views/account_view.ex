defmodule BlueJetWeb.AccountView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :name,
    :mode,
    :is_ready_for_live_transaction,
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
