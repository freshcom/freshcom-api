defmodule BlueJetWeb.PriceView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  alias BlueJet.Repo

  attributes [
    :status,
    :name,
    :label,
    :caption,
    :currency_code,
    :charge_cents,
    :estimate_average_percentage,
    :estimate_maximum_percentage,
    :minimum_order_quantity,
    :order_unit,
    :charge_unit,
    :estimate_by_default,
    :tax_one_percentage,
    :tax_two_percentage,
    :tax_three_percentage,
    :start_time,
    :end_time,
    :custom_data,
    :locale,
    :inserted_at,
    :updated_at
  ]

  has_one :product, serializer: BlueJetWeb.ProductView, identifiers: :always
  has_many :children, serializer: BlueJetWeb.PriceView, identifiers: :when_included

  def type(_, _) do
    "Price"
  end

  def locale(_, %{ assigns: %{ locale: locale } }), do: locale

  def product(struct, %{ assigns: %{ locale: locale } }) do
    case struct.product do
      %Ecto.Association.NotLoaded{} ->
        struct
        |> Ecto.assoc(:product)
        |> Repo.one()
      other -> other
    end
  end
end
