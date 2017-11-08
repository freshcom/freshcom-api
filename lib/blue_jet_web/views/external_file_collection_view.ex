defmodule BlueJetWeb.ExternalFileCollectionView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  alias BlueJet.Repo
  alias BlueJet.FileStorage.ExternalFileCollection

  attributes [:name, :label, :file_count, :custom_data, :locale, :inserted_at, :updated_at]

  has_many :files, serializer: BlueJetWeb.ExternalFileView, identifiers: :when_included
  has_one :owner, serializer: BlueJetWeb.OwnerView, identifiers: :always

  def type(_external_file_collection, _conn) do
    "ExternalFileCollection"
  end

  def locale(_, %{ assigns: %{ locale: locale } }), do: locale

  def file_count(efc, _conn) do
    ExternalFileCollection.file_count(efc)
  end

  def files(struct, _) do
    case struct.files do
      %Ecto.Association.NotLoaded{} ->
        struct
        |> Ecto.assoc(:files)
        |> Repo.all()
      other -> other
    end
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
