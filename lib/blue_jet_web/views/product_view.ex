defmodule BlueJetWeb.ProductView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :status,
    :code,
    :kind,
    :name_sync,
    :name,
    :print_name,
    :item_mode,
    :caption,
    :primary,
    :description,
    :custom_data,
    :locale,
    :inserted_at,
    :updated_at
  ]

  has_one :avatar, serializer: BlueJetWeb.ExternalFileView, identifiers: :when_included
  has_one :default_price, serializer: BlueJetWeb.PriceView, identifiers: :when_included
  has_one :parent, serializer: BlueJetWeb.ProductView, identifiers: :always
  has_one :source, serializer: BlueJetWeb.IdentifierView, identifiers: :always

  has_many :external_file_collections, serializer: BlueJetWeb.ExternalFileCollectionView, identifiers: :when_included
  has_many :items, serializer: BlueJetWeb.ProductView, identifiers: :when_included
  has_many :variants, serializer: BlueJetWeb.ProductView, identifiers: :when_included
  has_many :prices, serializer: BlueJetWeb.PriceView, identifiers: :when_included

  def locale(_, %{ assigns: %{ locale: locale } }), do: locale

  def type(_, _) do
    "Product"
  end

  def parent(product = %{ parent: %Ecto.Association.NotLoaded{} }, _) do
    case product.parent_id do
      nil -> nil
      _ -> %{ type: "Product", id: product.parent_id }
    end
  end
  def parent(product, _), do: product.parent

  def source(%{ source_id: nil }, _) do
    nil
  end
  def source(%{ source_id: source_id, source_type: source_type }, _) do
    %{ id: source_id, type: source_type }
  end

  def kind(struct, _) do
    Inflex.camelize(struct.kind, :lower)
  end

  def name_sync(struct, _) do
    Inflex.camelize(struct.name_sync, :lower)
  end
end
