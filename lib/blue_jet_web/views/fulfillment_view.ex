defmodule BlueJetWeb.FulfillmentView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :code,
    :name,
    :label,

    :print_name,

    :caption,
    :description,
    :custom_data,

    :inserted_at,
    :updated_at
  ]

  has_one :source, serializer: BlueJetWeb.IdentifierView, identifiers: :always

  has_many :line_items, serializer: BlueJetWeb.FulfillmentLineItemView, identifiers: :when_included
  has_many :external_file_collections, serializer: BlueJetWeb.FileCollectionView, identifiers: :when_included

  def type do
    "Fulfillment"
  end

  def source(%{ source_id: nil }, _), do: nil
  def source(%{ source_id: source_id, source_type: source_type, source: nil }, _), do: %{ id: source_id, type: source_type }
  def source(%{ source: source }, _), do: source
end
