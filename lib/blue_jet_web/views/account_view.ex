defmodule BlueJetWeb.AccountView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [:name, :default_locale]

  def type(_, _) do
    "Account"
  end
end
