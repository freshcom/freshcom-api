defmodule BlueJetWeb.RefundView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  alias BlueJet.Repo

  attributes [
    :amount_cents,
    :custom_data,
    :inserted_at
  ]

  has_one :payment, serializer: BlueJetWeb.PaymentView, identifiers: :always

  def type(_, _) do
    "Refund"
  end

  def payment(struct, conn) do
    case struct.payment do
      %Ecto.Association.NotLoaded{} ->
        struct
        |> Ecto.assoc(:payment)
        |> Repo.one()
      other -> other
    end
  end
end
