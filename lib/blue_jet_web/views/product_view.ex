defmodule BlueJetWeb.ProductView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [:status, :name, :print_name, :item_mode, :caption, :description, :custom_data, :locale, :inserted_at, :updated_at]

  has_one :avatar, serializer: BlueJetWeb.ExternalFileView, identifiers: :when_included
  has_many :external_file_collections, serializer: BlueJetWeb.ExternalFileCollectionView, identifiers: :when_included
  has_many :items, serializer: BlueJetWeb.ProductItemView, identifiers: :when_included
  has_many :prices, serializer: BlueJetWeb.PriceView, identifiers: :when_included

  def locale(_, %{ assigns: %{ locale: locale } }), do: locale

  def type(_, _) do
    "Product"
  end
end
