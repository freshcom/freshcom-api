defmodule BlueJet.ExternalFileView do
  use BlueJet.Web, :view
  use JaSerializer.PhoenixView

  attributes [:name, :url, :status, :content_type, :size_bytes, :public_readable, :version_name, :system_tag, :original_id, :inserted_at, :updated_at]

  def type do
    "ExternalFile"
  end

  # Avoid conflicts with path helper url/1
  def url(external_file, _conn) do
    external_file.url
  end
end
