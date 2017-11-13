defmodule BlueJetWeb.PaymentView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  alias BlueJet.Repo

  attributes [
    :status,

    :gateway,
    :processor,
    :method,

    :amount_cents,
    :refunded_amount_cents,
    :gross_amount_cents,
    :transaction_fee_cents,
    :refunded_transaction_fee_cents,
    :net_amount_cents,

    :billing_address_line_one,
    :billing_address_line_two,
    :billing_address_province,
    :billing_address_city,
    :billing_address_country_code,
    :billing_address_postal_code,

    :target_id,
    :target_type,

    :owner_id,
    :owner_type,

    :authorized_at,
    :captured_at,
    :refunded_at,

    :custom_data,
    :inserted_at,
    :updated_at
  ]

  has_many :refunds, serializer: BlueJetWeb.RefundView, identifiers: :when_included
  has_one :target, serializer: BlueJetWeb.IdentifierView, identifiers: :always
  has_one :owner, serializer: BlueJetWeb.IdentifierView, identifiers: :always

  def type(_, _) do
    "Payment"
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
