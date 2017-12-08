defmodule BlueJetWeb.PointTransactionView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  alias BlueJet.Repo

  attributes [
    :amount,
    :status,
    :reason_label,
    :balance_after_commit,
    :description,
    :inserted_at
  ]

  has_one :point_account, serializer: BlueJetWeb.PointAccountView, identifiers: :always
  has_one :source, serializer: BlueJetWeb.IdentifierView, identifiers: :always

  def type(_, _) do
    "PointTransaction"
  end

  def locale(_, %{ assigns: %{ locale: locale } }), do: locale

  def source(point_transaction = %{ source_id: nil }, _), do: nil
  def source(point_transaction = %{ source_id: source_id, source_type: source_type }, _) do
    %{ id: source_id, type: source_type }
  end

  def point_account(point_transaction = %{ point_account: nil }, _) do
    case point_transaction.point_account_id do
      nil -> nil
      _ -> %{ type: "PointAccount", id: point_transaction.point_account_id }
    end
  end
  def point_account(point_transaction, _), do: Map.get(point_transaction, :point_account)
end
