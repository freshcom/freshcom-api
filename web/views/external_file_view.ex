defmodule BlueJet.ExternalFileView do
  use BlueJet.Web, :view
  use JaSerializer.PhoenixView

  attributes [:name, :url, :status, :content_type, :size_bytes, :public_readable, :version_name, :system_tag, :original_id, :inserted_at, :updated_at]

  def type do
    "ExternalFile"
  end

  def url(external_file, _conn) do
    BlueJet.ExternalFile.url(external_file)
  end
end
