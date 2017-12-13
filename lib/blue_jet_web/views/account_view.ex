defmodule BlueJetWeb.AccountView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [:name, :default_locale, :test_account_id]

  def type(_, _) do
    "Account"
  end
end
