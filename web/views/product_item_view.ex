defmodule BlueJet.ProductItemView do
  use BlueJet.Web, :view
  use JaSerializer.PhoenixView

  attributes [:code, :status, :short_name, :sort_index, :source_quantity, :maximum_order_quantity,
    :primary, :print_name, :custom_data, :locale, :inserted_at, :updated_at]

  has_one :avatar, serializer: BlueJet.ExternalFileView, identifiers: :when_included
  has_one :product, serializer: BlueJet.ProductView, identifiers: :when_included
  has_one :sku, serializer: BlueJet.SkuView, identifiers: :when_included

  def type(_, _) do
    "ProductItem"
  end

  def locale(_, %{ assigns: %{ locale: locale } }), do: locale
end
