defmodule BlueJetWeb.PointAccountView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :status,
    :balance
  ]

  has_one :customer, serializer: BlueJetWeb.CustomerView, identifiers: :always
  has_many :transactions, serializer: BlueJetWeb.PointTransactionView, identifiers: :when_included

  def type(_, _) do
    "PointAccount"
  end

  def locale(_, %{ assigns: %{ locale: locale } }), do: locale

  def customer(point_account = %{ customer: %Ecto.Association.NotLoaded{} }, _) do
    case point_account.customer_id do
      nil -> nil
      _ -> %{ type: "Customer", id: point_account.customer_id }
    end
  end
  def customer(point_account, _), do: point_account.customer
end
