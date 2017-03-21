defmodule BlueJet.SkuView do
  use BlueJet.Web, :view
  use JaSerializer.PhoenixView

  attributes [:number, :name, :print_name, :inserted_at, :updated_at]
  

end
