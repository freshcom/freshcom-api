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
    :price_charge_amount_cents,
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
  has_one :product, serializer: BlueJetWeb.ProductView, identifiers: :always
  has_one :price, serializer: BlueJetWeb.PriceView, identifiers: :always
  has_one :order, serializer: BlueJetWeb.OrderView, identifiers: :always

  def type(_, _) do
    "OrderLineItem"
  end

  def order(struct, _) do
    case struct.order do
      %Ecto.Association.NotLoaded{} ->
        struct
        |> Ecto.assoc(:order)
        |> Repo.one()
      other -> other
    end
  end

  def product(struct, _) do
    case struct.product do
      %Ecto.Association.NotLoaded{} ->
        struct
        |> Ecto.assoc(:product)
        |> Repo.one()
      other -> other
    end
  end

  def price(struct, _) do
    case struct.price do
      %Ecto.Association.NotLoaded{} ->
        struct
        |> Ecto.assoc(:price)
        |> Repo.one()
      other -> other
    end
  end
end
