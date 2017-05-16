defmodule BlueJet.RefreshTokenView do
  use BlueJet.Web, :view
  use JaSerializer.PhoenixView

  def type do
    "RefreshToken"
  end
end
