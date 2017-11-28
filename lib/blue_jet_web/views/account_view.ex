defmodule BlueJetWeb.AccountView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [:name]

  def type(_, _) do
    "Account"
  end
end
