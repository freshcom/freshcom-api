defmodule BlueJet.S3FileView do
  use BlueJet.Web, :view
  use JaSerializer.PhoenixView

  attributes [:name, :presigned_url, :status, :content_type, :size_bytes, :public_readable, :version_name, :system_tag, :original_id, :inserted_at, :updated_at]

  def type do
    "S3File"
  end
end
