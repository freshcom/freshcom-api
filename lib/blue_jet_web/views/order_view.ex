defmodule BlueJetWeb.OrderView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  alias BlueJet.Repo

  attributes [
    :code,
    :status,
    :payment_status,
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

    :is_estimate,

    :sub_total_cents,
    :tax_one_cents,
    :tax_two_cents,
    :tax_three_cents,
    :grand_total_cents,
    :authorization_cents,

    :fulfillment_method,

    :opened_at,
    :confirmation_email_sent_at,
    :receipt_email_sent_at,

    :custom_data,
    :inserted_at,
    :updated_at
  ]

  has_one :customer, serializer: BlueJetWeb.CustomerView, identifiers: :always
  has_many :root_line_items, serializer: BlueJetWeb.OrderLineItemView, identifiers: :when_included
  has_many :payments, serializer: BlueJetWeb.PaymentView, identifiers: :when_included

  def type(_, _) do
    "Order"
  end

  def status(order, _) do
    Inflex.camelize(order.status, :lower)
  end

  def payment_status(order, _) do
    Inflex.camelize(order.payment_status, :lower)
  end

  def customer(struct, conn) do
    case struct.customer do
      %Ecto.Association.NotLoaded{} ->
        struct
        |> Ecto.assoc(:customer)
        |> Repo.one()
      other -> other
    end
  end
end
