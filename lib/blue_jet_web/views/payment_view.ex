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

  has_many :refunds, serializer: BlueJetWeb.RefundView, identifiers: :when_included

  def type(_, _) do
    "Payment"
  end

  def owner(struct, _) do
    %{
      id: struct.owner_id,
      type: struct.owner_type
    }
  end
end
