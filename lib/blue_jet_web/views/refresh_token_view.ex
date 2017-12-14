defmodule BlueJetWeb.RefreshTokenView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [:prefixed_id]

  def type do
    "RefreshToken"
  end
end
