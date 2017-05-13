defmodule BlueJet.JwtView do
  use BlueJet.Web, :view
  use JaSerializer.PhoenixView

  attributes [:value, :name]

  def type do
    "Jwt"
  end
end
