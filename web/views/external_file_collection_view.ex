defmodule BlueJet.ExternalFileCollectionView do
  use BlueJet.Web, :view
  use JaSerializer.PhoenixView

  attributes [:name, :label, :file_count, :inserted_at, :updated_at]

  has_many :files, serializer: BlueJet.ExternalFileView, identifiers: :when_included

  def type(_external_file_collection, _conn) do
    "ExternalFileCollection"
  end

  def file_count(external_file_collection, _conn) do
    length(external_file_collection.file_ids)
  end
end
