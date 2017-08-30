defmodule BlueJetWeb.ExternalFileView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  alias BlueJet.FileStorage.ExternalFile

  attributes [:name, :url, :status, :content_type, :size_bytes, :public_readable, :version_name, :system_tag, :original_id, :inserted_at, :updated_at]

  def type do
    "ExternalFile"
  end

  # Avoid conflicts with path helper url/1
  def url(external_file, _conn) do
    ExternalFile.url(external_file)
  end
end
