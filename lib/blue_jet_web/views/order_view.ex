defmodule BlueJetWeb.OrderView do
  use BlueJetWeb, :view
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

    :sub_total_cents,
    :tax_one_cents,
    :tax_two_cents,
    :tax_three_cents,
    :grand_total_cents,

    :fulfillment_method,

    :placed_at,
    :confirmation_email_sent_at,
    :receipt_email_sent_at,

    :custom_data,
    :inserted_at,
    :updated_at
  ]

  has_one :customer, serializer: BlueJetWeb.CustomerView, identifiers: :when_included
  has_many :root_line_items, serializer: BlueJetWeb.OrderLineItemView, identifiers: :when_included

  def type(_, _) do
    "Order"
  end
end
