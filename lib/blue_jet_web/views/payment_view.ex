defmodule BlueJetWeb.PaymentView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :status,

    :gateway,
    :processor,
    :method,

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

  has_one :order, serializer: BlueJetWeb.OrderView, identifiers: :when_included

  def type(_, _) do
    "Payment"
  end
end
