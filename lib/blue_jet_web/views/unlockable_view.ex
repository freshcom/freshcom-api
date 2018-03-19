defmodule BlueJetWeb.UnlockableView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :status,
    :code,
    :name,
    :label,

    :print_name,

    :caption,
    :description,
    :custom_data,

    :inserted_at,
    :updated_at
  ]

  has_one :avatar, serializer: BlueJetWeb.FileView, identifiers: :always
  has_one :file, serializer: BlueJetWeb.FileView, identifiers: :always
  has_many :file_collections, serializer: BlueJetWeb.FileCollectionView, identifiers: :when_included

  def type do
    "Unlockable"
  end

  def avatar(%{ avatar_id: nil }, _), do: nil
  def avatar(%{ avatar_id: avatar_id, avatar: nil }, _), do: %{ id: avatar_id, type: "File" }
  def avatar(%{ avatar: avatar }, _), do: avatar

  def file(%{ file_id: nil }, _), do: nil
  def file(%{ file_id: file_id, file: nil }, _), do: %{ id: file_id, type: "File" }
  def file(%{ file: file }, _), do: file
end
