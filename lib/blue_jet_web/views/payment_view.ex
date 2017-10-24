defmodule BlueJetWeb.PaymentView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  alias BlueJet.Repo

  attributes [
    :status,

    :gateway,
    :processor,
    :method,

    :pending_amount_cents,
    :authorized_amount_cents,
    :paid_amount_cents,
    :refunded_amount_cents,

    :billing_address_line_one,
    :billing_address_line_two,
    :billing_address_province,
    :billing_address_city,
    :billing_address_country_code,
    :billing_address_postal_code,

    :authorized_at,
    :captured_at,
    :refunded_at,

    :custom_data,
    :inserted_at,
    :updated_at
  ]

  has_one :order, serializer: BlueJetWeb.OrderView, identifiers: :always

  def type(_, _) do
    "Payment"
  end

  def order(struct, conn) do
    case struct.order do
      %Ecto.Association.NotLoaded{} ->
        struct
        |> Ecto.assoc(:order)
        |> Repo.one()
      other -> other
    end
  end
end
