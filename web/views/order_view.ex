defmodule BlueJet.OrderView do
  use BlueJet.Web, :view
  use JaSerializer.PhoenixView

  attributes [
    :code,
    :status,
    :system_tag,
    :label,

    :email,
    :first_name,
    :last_name,
    :phone_number,

    :delivery_address_line_one,
    :delivery_address_line_two,
    :delivery_address_province,
    :delivery_address_city,
    :delivery_address_country_code,
    :delivery_address_postal_code,

    :billing_address_line_one,
    :billing_address_line_two,
    :billing_address_province,
    :billing_address_city,
    :billing_address_country_code,
    :billing_address_postal_code,

    :sub_total_cents,
    :tax_one_cents,
    :tax_two_cents,
    :tax_three_cents,
    :grand_total_cents,

    :payment_status,
    :payment_gateway,
    :payment_processor,
    :payment_method,

    :fulfillment_method,

    :placed_at,
    :confirmation_email_sent_at,
    :receipt_email_sent_at,

    :custom_data,
    :inserted_at,
    :updated_at
  ]

  has_one :customer, serializer: BlueJet.CustomerView, identifiers: :when_included
end
