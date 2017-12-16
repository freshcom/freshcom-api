defmodule BlueJetWeb.ProductCollectionView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :code,
    :name,
    :status,
    :label,
    :sort_index,
    :custom_data,
    :locale,
    :inserted_at,
    :updated_at
  ]

  has_many :memberships, serializer: BlueJetWeb.ProductCollectionMembershipView, identifiers: :when_included
  has_many :products, serializer: BlueJetWeb.ProductView, identifiers: :when_included

  def type(_, _conn) do
    "ProductCollection"
  end

  def locale(_, %{ assigns: %{ locale: locale } }), do: locale
end
