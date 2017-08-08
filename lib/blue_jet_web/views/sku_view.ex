defmodule BlueJetWeb.SkuView do
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

  has_one :avatar, serializer: BlueJetWeb.ExternalFileView, identifiers: :when_included
  has_many :external_file_collections, serializer: BlueJetWeb.ExternalFileCollectionView, identifiers: :when_included

  def type(_, _) do
    "Sku"
  end

  def locale(_, %{ assigns: %{ locale: locale } }), do: locale
end
