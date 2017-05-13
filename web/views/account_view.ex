defmodule BlueJet.AccountView do
  use BlueJet.Web, :view
  use JaSerializer.PhoenixView

  attributes [:name, :inserted_at, :updated_at]
  

end
