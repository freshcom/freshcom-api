defmodule BlueJetWeb.ProductView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :status,
    :code,
    :name,
    :label,

    :name_sync,
    :short_name,
    :print_name,
    :kind,

    :sort_index,
    :goods_quantity,
    :primary,
    :maximum_public_order_quantity,
    :auto_fulfill,

    :caption,
    :description,
    :custom_data,

    :inserted_at,
    :updated_at
  ]

  has_one :avatar, serializer: BlueJetWeb.FileView, identifiers: :always
  has_one :parent, serializer: BlueJetWeb.ProductView, identifiers: :always
  has_one :goods, serializer: BlueJetWeb.IdentifierView, identifiers: :always

  has_one :default_price, serializer: BlueJetWeb.PriceView, identifiers: :when_included
  has_many :file_collections, serializer: BlueJetWeb.FileCollectionView, identifiers: :when_included
  has_many :items, serializer: BlueJetWeb.ProductView, identifiers: :when_included
  has_many :variants, serializer: BlueJetWeb.ProductView, identifiers: :when_included
  has_many :prices, serializer: BlueJetWeb.PriceView, identifiers: :when_included

  def type do
    "Product"
  end

  def parent(%{ parent_id: nil }, _), do: nil
  def parent(%{ parent_id: parent_id, parent: %Ecto.Association.NotLoaded{} }, _), do: %{ id: parent_id, type: "Product" }
  def parent(%{ parent: parent }, _), do: parent

  def goods(%{ goods_id: nil }, _), do: nil
  def goods(%{ goods_id: goods_id, goods_type: goods_type, goods: nil }, _), do: %{ id: goods_id, type: goods_type }
  def goods(%{ goods: goods }, _), do: goods

  def kind(struct, _) do
    Inflex.camelize(struct.kind, :lower)
  end

  def name_sync(struct, _) do
    Inflex.camelize(struct.name_sync, :lower)
  end
end
