defmodule BlueJetWeb.FileCollectionMembershipView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :sort_index,
    :inserted_at,
    :updated_at
  ]

  has_one :collection, serializer: BlueJetWeb.FileCollectionView, identifiers: :always
  has_one :file, serializer: BlueJetWeb.FileView, identifiers: :always

  def type(_, _conn) do
    "FileCollectionMembership"
  end

  def collection(membership = %{ collection: %Ecto.Association.NotLoaded{} }, _) do
    case membership.collection_id do
      nil -> nil
      _ -> %{ type: "ProductCollection", id: membership.collection_id }
    end
  end
  def collection(membership, _), do: Map.get(membership, :collection)

  def file(membership = %{ file: %Ecto.Association.NotLoaded{} }, _) do
    case membership.file_id do
      nil -> nil
      _ -> %{ type: "Product", id: membership.file_id }
    end
  end
  def file(membership, _), do: Map.get(membership, :file)
end
