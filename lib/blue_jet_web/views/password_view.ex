defmodule BlueJetWeb.PasswordView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  def type do
    "Password"
  end
end
