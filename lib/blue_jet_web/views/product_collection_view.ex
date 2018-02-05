defmodule BlueJetWeb.ProductCollectionView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :status,
    :code,
    :name,
    :label,
    :sort_index,

    :caption,
    :description,
    :custom_data,

    :inserted_at,
    :updated_at
  ]

  has_one :avatar, serializer: BlueJetWeb.FileView, identifiers: :always

  has_many :memberships, serializer: BlueJetWeb.ProductCollectionMembershipView, identifiers: :when_included
  has_many :products, serializer: BlueJetWeb.ProductView, include: false, identifiers: :when_included

  def type do
    "ProductCollection"
  end
end
