defmodule BlueJetWeb.UnlockableView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [:code, :status, :name, :print_name, :custom_data, :locale, :inserted_at, :updated_at]

  has_one :avatar, serializer: BlueJetWeb.ExternalFileView, identifiers: :when_included
  has_many :external_file_collections, serializer: BlueJetWeb.ExternalFileCollectionView, identifiers: :when_included

  def locale(_, %{ assigns: %{ locale: locale } }), do: locale

  def type(_, _) do
    "Unlockable"
  end
end
