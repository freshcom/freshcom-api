defmodule BlueJetWeb.StockableView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :code,
    :status,
    :name,
    :print_name,
    :unit_of_measure,
    :variable_weight,
    :storage_type,
    :storage_size,
    :stackable,
    :caption,
    :description,
    :specification,
    :storage_description,
    :custom_data,
    :locale,
    :inserted_at,
    :updated_at
  ]

  has_one :avatar, serializer: BlueJetWeb.ExternalFileView, identifiers: :always
  has_many :external_file_collections, serializer: BlueJetWeb.ExternalFileCollectionView, identifiers: :always

  def type(_, _) do
    "Stockable"
  end

  def locale(_, %{ assigns: %{ locale: locale } }), do: locale
end