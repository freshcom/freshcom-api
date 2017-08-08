defmodule BlueJetWeb.RefreshTokenView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  def type do
    "RefreshToken"
  end
end
