defmodule BlueJetWeb.PhoneVerificationCodeView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :phone_number
  ]

  def type do
    "PhoneVerificationCode"
  end
end
