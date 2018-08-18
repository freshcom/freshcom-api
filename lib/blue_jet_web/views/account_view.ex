defmodule BlueJetWeb.AccountView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :name,
    :mode,
    :company_name,
    :website_url,
    :support_email,
    :tech_email,
    :is_ready_for_live_transaction,
    :default_auth_method,
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
