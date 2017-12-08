defmodule BlueJetWeb.UserView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [:email, :first_name, :last_name, :other_name, :inserted_at, :updated_at]
end
