defmodule BlueJet.ProductView do
  use BlueJet.Web, :view
  use JaSerializer.PhoenixView

  attributes [:number, :name, :author, :inserted_at, :updated_at]


end
