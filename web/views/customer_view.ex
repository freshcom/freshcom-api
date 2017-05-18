defmodule BlueJet.CustomerView do
  use BlueJet.Web, :view
  use JaSerializer.PhoenixView

  attributes [:first_name, :last_name, :email, :encrypted_password, :display_name, :inserted_at, :updated_at]
  

end
