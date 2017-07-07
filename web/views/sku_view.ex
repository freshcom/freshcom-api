defmodule BlueJet.SkuView do
  use BlueJet.Web, :view
  use JaSerializer.PhoenixView

  alias BlueJet.Repo

  attributes [
    :code,
    :status,
    :name,
    :print_name,
    :unit_of_measure,
    :variable_weight,
    :storage_type,
    :storage_size,
    :stackable,
    :caption,
    :description,
    :specification,
    :storage_description,
    :custom_data,
    :locale,
    :inserted_at,
    :updated_at
  ]

  has_one :avatar, serializer: BlueJet.ExternalFileView, identifiers: :when_included
  has_many :external_file_collections, serializer: BlueJet.ExternalFileCollectionView, identifiers: :when_included

  def type(_, _) do
    "Sku"
  end

  def locale(_, %{ assigns: %{ locale: locale } }), do: locale

  def avatar(struct, _) do
    case struct.avatar do
      %Ecto.Association.NotLoaded{} ->
        struct
        |> Ecto.assoc(:avatar)
        |> Repo.one
      other -> other
    end
  end

  def external_file_collections(struct, %{ assigns: %{ locale: locale } }) do
    case struct.external_file_collections do
      %Ecto.Association.NotLoaded{} ->
        struct
        |> Ecto.assoc(:external_file_collections)
        |> Repo.all
        |> Translation.translate_collection(locale)
      other -> other
    end
  end
end
