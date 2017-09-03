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
    :public_orderable,
    :estimate_by_default,
    :tax_one_rate,
    :tax_two_rate,
    :tax_three_rate,
    :start_time,
    :end_time,
    :custom_data,
    :locale,
    :inserted_at,
    :updated_at
  ]

  has_one :product_item, serializer: BlueJetWeb.ProductItemView, identifiers: :when_included

  def type(_, _) do
    "Price"
  end

  def charge_cents(struct, _) do
    struct.charge_cents.amount
  end

  def locale(_, %{ assigns: %{ locale: locale } }), do: locale

  def product_item(struct, %{ assigns: %{ locale: locale } }) do
    case struct.product_item do
      %Ecto.Association.NotLoaded{} ->
        [product_item] = struct
        |> Ecto.assoc(:product_item)
        |> Repo.one()
        |> Translation.translate(locale)
        product_item
      other -> other
    end
  end
end
