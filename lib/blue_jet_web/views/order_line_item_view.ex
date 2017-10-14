defmodule BlueJetWeb.OrderLineItemView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  alias BlueJet.Repo

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

  has_many :children, serializer: BlueJetWeb.OrderLineItemView, identifiers: :when_included
  has_one :product_item, serializer: BlueJetWeb.ProductItemView, identifiers: :always
  has_one :product, serializer: BlueJetWeb.ProductItemView, identifiers: :always
  has_one :price, serializer: BlueJetWeb.PriceView, identifiers: :always

  def type(_, _) do
    "OrderLineItem"
  end

  def product(struct, conn) do
    case struct.product do
      %Ecto.Association.NotLoaded{} ->
        struct
        |> Ecto.assoc(:product)
        |> Repo.one()
      other -> other
    end
  end

  def product_item(struct, conn) do
    case struct.product_item do
      %Ecto.Association.NotLoaded{} ->
        struct
        |> Ecto.assoc(:product_item)
        |> Repo.one()
      other -> other
    end
  end

  def price(struct, conn) do
    case struct.price do
      %Ecto.Association.NotLoaded{} ->
        struct
        |> Ecto.assoc(:price)
        |> Repo.one()
      other -> other
    end
  end
end
