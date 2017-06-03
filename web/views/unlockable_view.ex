defmodule BlueJet.UnlockableView do
  use BlueJet.Web, :view
  use JaSerializer.PhoenixView

  attributes [:code, :status, :name, :print_name, :inserted_at, :updated_at]
  

end
