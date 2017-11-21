defmodule BlueJetWeb.RefundView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  alias BlueJet.Repo

  attributes [
    :gateway,
    :amount_cents,
    :custom_data,
    :inserted_at
  ]

  has_one :payment, serializer: BlueJetWeb.PaymentView, identifiers: :always
  has_one :target, serializer: BlueJetWeb.IdentifierView, identifiers: :always
  has_one :owner, serializer: BlueJetWeb.IdentifierView, identifiers: :always

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

  def owner(struct, _) do
    %{
      id: struct.owner_id,
      type: struct.owner_type
    }
  end

  def target(struct, _) do
    %{
      id: struct.target_id,
      type: struct.target_type
    }
  end
end
