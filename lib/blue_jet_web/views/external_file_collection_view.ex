defmodule BlueJetWeb.ExternalFileCollectionView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  alias BlueJet.Repo
  alias BlueJet.FileStorage.ExternalFileCollection

  attributes [:name, :label, :file_count, :custom_data, :locale, :inserted_at, :updated_at]

  has_one :sku, serializer: BlueJetWeb.SkuView, identifiers: :always
  has_one :unlockable, serializer: BlueJetWeb.UnlockableView, identifiers: :always
  has_one :product, serializer: BlueJetWeb.ProductView, identifiers: :always
  has_many :files, serializer: BlueJetWeb.ExternalFileView, identifiers: :when_included

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

  def product(struct, _) do
    case struct.product do
      %Ecto.Association.NotLoaded{} ->
        struct
        |> Ecto.assoc(:product)
        |> Repo.one()
      other -> other
    end
  end
end
