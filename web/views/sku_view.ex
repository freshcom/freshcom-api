defmodule BlueJet.SkuView do
  use BlueJet.Web, :view
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

  has_one :avatar, serializer: BlueJet.ExternalFileView, identifiers: :when_included
  has_many :external_file_collections, serializer: BlueJet.ExternalFileCollectionView, identifiers: :when_included

  def locale(_sku, conn) do
    conn.assigns[:locale]
  end

  def type(_sku, _conn) do
    "Sku"
  end

end
