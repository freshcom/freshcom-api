defmodule BlueJetWeb.ExternalFileCollectionView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  alias BlueJet.FileStorage.ExternalFileCollection

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

  has_many :files, serializer: BlueJetWeb.ExternalFileView, identifiers: :when_included
  has_one :owner, serializer: BlueJetWeb.IdentifierView, identifiers: :always

  def type(_, _) do
    "ExternalFileCollection"
  end

  def file_count(efc, _conn) do
    ExternalFileCollection.file_count(efc)
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
