defmodule BlueJet.ExternalFileCollectionMembershipView do
  use BlueJet.Web, :view
  use JaSerializer.PhoenixView

  alias BlueJet.Repo

  attributes [
    :sort_index,
    :inserted_at,
    :updated_at]

  has_one :collection, serializer: BlueJet.ExternalFileCollectionView
  has_one :file, serializer: BlueJet.ExternalFileView

  def collection(struct, %{ assigns: %{ locale: locale } }) do
    case struct.collection do
      %Ecto.Association.NotLoaded{} ->
        struct
        |> Ecto.assoc(:collection)
        |> Repo.one
        |> Translation.translate(locale)
      other -> other
    end
  end

  def file(struct, _) do
    case struct.file do
      %Ecto.Association.NotLoaded{} ->
        struct
        |> Ecto.assoc(:file)
        |> Repo.one
      other -> other
    end
  end
end
