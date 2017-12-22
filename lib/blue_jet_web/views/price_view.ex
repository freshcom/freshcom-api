defmodule BlueJetWeb.PriceView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :status,
    :code,
    :name,
    :label,

    :currency_code,
    :charge_amount_cents,
    :charge_unit,
    :order_unit,

    :estimate_average_percentage,
    :estimate_maximum_percentage,
    :minimum_order_quantity,
    :estimate_by_default,

    :tax_one_percentage,
    :tax_two_percentage,
    :tax_three_percentage,

    :start_time,
    :end_time,

    :caption,
    :description,
    :custom_data,

    :inserted_at,
    :updated_at
  ]

  has_one :product, serializer: BlueJetWeb.ProductView, identifiers: :always
  has_many :children, serializer: BlueJetWeb.PriceView, identifiers: :when_included

  def type do
    "Price"
  end

  def product(%{ product_id: nil }, _), do: nil
  def product(%{ product_id: product_id, product: %Ecto.Association.NotLoaded{} }, _), do: %{ id: product_id, type: "Customer" }
  def product(%{ product: product }, _), do: product
end
