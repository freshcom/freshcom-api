defmodule BlueJetWeb.FileCollectionView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :status,
    :code,
    :name,
    :label,

    :file_count,

    :caption,
    :description,
    :custom_data,

    :inserted_at,
    :updated_at
  ]

  has_many :files, serializer: BlueJetWeb.FileView, identifiers: :when_included
  has_many :memberships, serializer: BlueJetWeb.FileCollectionMembershipView, identifiers: :when_included
  has_one :owner, serializer: BlueJetWeb.IdentifierView, identifiers: :always

  def type do
    "FileCollection"
  end

  def owner(struct, _) do
    if struct.owner_id do
      %{
        id: struct.owner_id,
        type: struct.owner_type
      }
    else
      nil
    end
  end
end
