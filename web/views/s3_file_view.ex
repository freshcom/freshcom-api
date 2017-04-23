defmodule BlueJet.S3FileView do
  use BlueJet.Web, :view
  use JaSerializer.PhoenixView

  attributes [:name, :url, :status, :content_type, :size_bytes, :public_readable, :version_name, :system_tag, :original_id, :inserted_at, :updated_at]

  def type do
    "S3File"
  end

  def url(s3_file, _conn) do
    BlueJet.S3File.url(s3_file)
  end
end
