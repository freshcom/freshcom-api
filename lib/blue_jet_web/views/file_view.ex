defmodule BlueJetWeb.FileView do
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
    "File"
  end

  # Avoid conflicts with path helper url/1
  def url(file, _) do
    file.url
  end
end
