defmodule BlueJetWeb.PointTransactionView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :status,
    :code,
    :name,
    :label,

    :reason_label,
    :amount,
    :balance_after_commit,

    :caption,
    :description,
    :custom_data,

    :committed_at,
    :inserted_at
  ]

  has_one :point_account, serializer: BlueJetWeb.PointAccountView, identifiers: :always
  has_one :source, serializer: BlueJetWeb.IdentifierView, identifiers: :always

  def type do
    "PointTransaction"
  end

  def source(%{ source_id: nil }, _), do: nil
  def source(%{ source_id: source_id, source_type: source_type, source: nil }, _), do: %{ id: source_id, type: source_type }
  def source(%{ source: source }, _), do: source

  def point_account(%{ point_account_id: nil }, _), do: nil

  def point_account(%{ point_account_id: point_account_id, point_account: %Ecto.Association.NotLoaded{} }, _) do
    %{ id: point_account_id, type: "PointAccount" }
  end

  def point_account(%{ point_account: point_account }, _), do: point_account
end
