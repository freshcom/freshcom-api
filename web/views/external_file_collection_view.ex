defmodule BlueJet.ExternalFileSetView do
  use BlueJet.Web, :view
  use JaSerializer.PhoenixView

  attributes [:name, :label, :inserted_at, :updated_at]

  def type(_external_file_collection, _conn) do
    "ExternalFileCollection"
  end
end
