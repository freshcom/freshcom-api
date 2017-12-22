defmodule BlueJetWeb.ExternalFileView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :status,
    :code,
    :name,
    :label,

    :content_type,
    :size_bytes,
    :public_readable,
    :url,

    :caption,
    :description,
    :custom_data,

    :inserted_at,
    :updated_at
  ]

  def type do
    "ExternalFile"
  end

  # Avoid conflicts with path helper url/1
  def url(external_file, _) do
    external_file.url
  end
end
