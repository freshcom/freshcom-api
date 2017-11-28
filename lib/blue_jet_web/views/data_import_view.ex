defmodule BlueJetWeb.DataImportView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :status,
    :data_url,
    :data_type,
    :inserted_at,
    :updated_at
  ]

  def type(_, _) do
    "DataImport"
  end

  def locale(_, %{ assigns: %{ locale: locale } }), do: locale
end
