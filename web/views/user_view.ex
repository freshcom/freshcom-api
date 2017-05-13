defmodule BlueJet.UserView do
  use BlueJet.Web, :view
  use JaSerializer.PhoenixView

  attributes [:email, :first_name, :last_name, :inserted_at, :updated_at]
end
