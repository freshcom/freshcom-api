defmodule BlueJet.ProductView do
  use BlueJet.Web, :view
  use JaSerializer.PhoenixView

  attributes [:status, :name, :item_mode, :caption, :description, :custom_data, :inserted_at, :updated_at]

  def locale(_, conn) do
    conn.assigns[:locale]
  end

  def type(_, _) do
    "Product"
  end
end
