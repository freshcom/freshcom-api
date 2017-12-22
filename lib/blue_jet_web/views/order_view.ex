defmodule BlueJetWeb.OrderView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :status,
    :code,
    :name,
    :label,

    :payment_status,
    :fulfillment_status,
    :fulfillment_method,
    :system_tag,

    :email,
    :first_name,
    :last_name,
    :phone_number,

    :sub_total_cents,
    :tax_one_cents,
    :tax_two_cents,
    :tax_three_cents,
    :grand_total_cents,
    :authorization_toal_cents,
    :is_estimate,

    :delivery_address_line_one,
    :delivery_address_line_two,
    :delivery_address_province,
    :delivery_address_city,
    :delivery_address_country_code,
    :delivery_address_postal_code,

    :opened_at,
    :confirmation_email_sent_at,
    :receipt_email_sent_at,

    :caption,
    :description,
    :custom_data,

    :inserted_at,
    :updated_at
  ]

  has_one :customer, serializer: BlueJetWeb.CustomerView, identifiers: :always
  has_many :root_line_items, serializer: BlueJetWeb.OrderLineItemView, identifiers: :when_included
  has_many :payments, serializer: BlueJetWeb.PaymentView, identifiers: :when_included

  def type do
    "Order"
  end

  def status(order, _) do
    Inflex.camelize(order.status, :lower)
  end

  def payment_status(order, _) do
    Inflex.camelize(order.payment_status, :lower)
  end

  def customer(%{ customer_id: nil }, _) do
    nil
  end
  def customer(order = %{ customer_id: customer_id }, _) do
    case order.customer do
      nil ->
        %{ id: customer_id, type: "Customer" }
      other -> other
    end
  end
end
