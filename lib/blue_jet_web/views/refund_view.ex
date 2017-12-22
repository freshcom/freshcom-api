defmodule BlueJetWeb.RefundView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  alias BlueJet.Repo

  attributes [
    :code,
    :label,
    :gateway,
    :amount_cents,
    :caption,
    :descrption,
    :custom_data,
    :inserted_at
  ]

  has_one :payment, serializer: BlueJetWeb.PaymentView, identifiers: :always
  has_one :target, serializer: BlueJetWeb.IdentifierView, identifiers: :always
  has_one :owner, serializer: BlueJetWeb.IdentifierView, identifiers: :always

  def type do
    "Refund"
  end

  def payment(%{ payment_id: nil }, _), do: nil
  def payment(%{ payment_id: payment_id, payment: %Ecto.Association.NotLoaded{} }, _), do: %{ id: payment_id, type: "Product" }
  def payment(%{ payment: payment }, _), do: payment

  def owner(%{ owner_id: nil }, _), do: nil
  def owner(%{ owner_id: owner_id, owner_type: owner_type, owner: nil }, _), do: %{ id: owner_id, type: owner_type }
  def owner(%{ owner: owner }, _), do: owner

  def target(%{ target_id: nil }, _), do: nil
  def target(%{ target_id: target_id, target_type: target_type, target: nil }, _), do: %{ id: target_id, type: target_type }
  def target(%{ target: target }, _), do: target
end
