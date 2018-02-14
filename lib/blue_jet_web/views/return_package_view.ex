defmodule BlueJetWeb.ReturnPackageView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :code,
    :name,
    :label,
    :system_label,

    :print_name,

    :caption,
    :description,
    :custom_data,

    :inserted_at,
    :updated_at
  ]

  has_one :source, serializer: BlueJetWeb.IdentifierView, identifiers: :always

  has_many :items, serializer: BlueJetWeb.ReturnItemView, identifiers: :when_included
  has_many :file_collections, serializer: BlueJetWeb.FileCollectionView, identifiers: :when_included

  def type do
    "ReturnPackage"
  end

  def order(%{ order_id: nil }, _), do: nil
  def order(%{ order_id: order_id, order: nil }, _), do: %{ id: order_id, type: "Order" }
  def order(%{ order: order }, _), do: order
end
