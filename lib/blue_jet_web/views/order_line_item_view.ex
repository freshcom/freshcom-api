defmodule BlueJetWeb.OrderLineItemView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :code,
    :name,
    :label,

    :fulfillment_status,

    :print_name,
    :is_leaf,
    :order_quantity,
    :charge_quantity,

    :price_name,
    :price_label,
    :price_caption,
    :price_order_unit,
    :price_charge_unit,
    :price_currency_code,
    :price_charge_amount_cents,
    :price_estimate_average_percentage,
    :price_estimate_maximum_percentage,
    :price_tax_one_percentage,
    :price_tax_two_percentage,
    :price_tax_three_percentage,
    :price_estimate_by_default,
    :price_end_time,

    :sub_total_cents,
    :tax_one_cents,
    :tax_two_cents,
    :tax_three_cents,
    :grand_total_cents,
    :authorization_total_cents,
    :is_estimate,
    :auto_fulfill,

    :caption,
    :description,
    :custom_data,

    :inserted_at,
    :updated_at
  ]

  has_many :children, serializer: BlueJetWeb.OrderLineItemView, identifiers: :when_included
  has_one :product, serializer: BlueJetWeb.ProductView, identifiers: :always
  has_one :price, serializer: BlueJetWeb.PriceView, identifiers: :always
  has_one :order, serializer: BlueJetWeb.OrderView, identifiers: :always

  def type do
    "OrderLineItem"
  end

  def order(%{ order_id: nil }, _), do: nil
  def order(%{ order_id: order_id, order: %Ecto.Association.NotLoaded{} }, _), do: %{ id: order_id, type: "Customer" }
  def order(%{ order: order }, _), do: order

  def product(%{ product_id: nil }, _), do: nil
  def product(%{ product_id: product_id, product: %Ecto.Association.NotLoaded{} }, _), do: %{ id: product_id, type: "Customer" }
  def product(%{ product: product }, _), do: product

  def price(%{ price_id: nil }, _), do: nil
  def price(%{ price_id: price_id, price: %Ecto.Association.NotLoaded{} }, _), do: %{ id: price_id, type: "Customer" }
  def price(%{ price: price }, _), do: price
end
