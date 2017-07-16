defmodule BlueJet.ProductView do
  use BlueJet.Web, :view
  use JaSerializer.PhoenixView

  attributes [:status, :name, :item_mode, :caption, :description, :custom_data, :inserted_at, :updated_at]

  has_one :avatar, serializer: BlueJet.ExternalFileView, identifiers: :when_included
  has_many :external_file_collections, serializer: BlueJet.ExternalFileCollectionView, identifiers: :when_included

  def locale(_, %{ assigns: %{ locale: locale } }), do: locale

  def type(_, _) do
    "Product"
  end
end
