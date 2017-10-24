defmodule BlueJetWeb.RefundView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :amount_cents,
    :custom_data,
    :inserted_at
  ]

  has_one :payment, serializer: BlueJetWeb.PaymentView, identifiers: :always

  def type(_, _) do
    "Refund"
  end
end
