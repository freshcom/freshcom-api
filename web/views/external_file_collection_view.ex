defmodule BlueJet.ExternalFileCollectionView do
  use BlueJet.Web, :view
  use JaSerializer.PhoenixView

  alias BlueJet.Repo
  alias BlueJet.ExternalFileCollection

  attributes [:name, :label, :file_count, :custom_data, :inserted_at, :updated_at]

  has_one :sku, serializer: BlueJet.SkuView, identifiers: :when_included
  has_one :unlockable, serializer: BlueJet.UnlockableView, identifiers: :when_included
  has_many :files, serializer: BlueJet.ExternalFileView, identifiers: :when_included

  def type(_external_file_collection, _conn) do
    "ExternalFileCollection"
  end

  def file_count(external_file_collection, _conn) do
    length(external_file_collection.file_ids)
  end

  def files(struct, _) do
    case struct.files do
      %Ecto.Association.NotLoaded{} ->
        struct |> ExternalFileCollection.files()
      other -> other
    end
  end

  def sku(struct, _) do
    case struct.sku do
      %Ecto.Association.NotLoaded{} ->
        struct
        |> Ecto.assoc(:sku)
        |> Repo.one()
      other -> other
    end
  end

  def unlockable(struct, _) do
    case struct.unlockable do
      %Ecto.Association.NotLoaded{} ->
        struct
        |> Ecto.assoc(:unlockable)
        |> Repo.one()
      other -> other
    end
  end
end
