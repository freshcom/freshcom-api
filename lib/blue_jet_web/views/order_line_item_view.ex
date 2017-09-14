defmodule BlueJetWeb.OrderLineItemView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :code,
    :name,
    :label,
    :print_name,

    :price_name,
    :price_label,
    :price_caption,
    :price_order_unit,
    :price_charge_unit,
    :price_currency_code,
    :price_charge_cents,
    :price_estimate_average_percentage,
    :price_estimate_maximum_percentage,
    :price_tax_one_percentage,
    :price_tax_two_percentage,
    :price_tax_three_percentage,
    :price_estimate_by_default,
    :price_end_time,

    :order_quantity,
    :charge_quantity,

    :sub_total_cents,
    :tax_one_cents,
    :tax_two_cents,
    :tax_three_cents,
    :grand_total_cents,

    :is_estimate,

    :custom_data,
    :inserted_at,
    :updated_at
  ]

  def type(_, _) do
    "OrderLineItem"
  end

  def price_charge_cents(struct = %{ price_charge_cents: price_charge_cents  }, _) when not is_nil(price_charge_cents) do
    struct.price_charge_cents.amount
  end
  def price_charge_cents(_, _), do: nil

  def sub_total_cents(struct, _) do
    struct.sub_total_cents.amount
  end

  def tax_one_cents(struct, _) do
    struct.tax_one_cents.amount
  end

  def tax_two_cents(struct, _) do
    struct.tax_two_cents.amount
  end

  def tax_three_cents(struct, _) do
    struct.tax_three_cents.amount
  end

  def grand_total_cents(struct, _) do
    struct.grand_total_cents.amount
  end
end
