defmodule BlueJet.S3FileSetView do
  use BlueJet.Web, :view
  use JaSerializer.PhoenixView

  attributes [:name, :label, :inserted_at, :updated_at]

  def type(_s3_file_set, _conn) do
    "S3FileSet"
  end
end
