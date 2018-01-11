defmodule BlueJetWeb.PasswordResetTokenView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :email
  ]

  def type do
    "PasswordResetToken"
  end
end
