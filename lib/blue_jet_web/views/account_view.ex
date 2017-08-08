defmodule BlueJetWeb.AccountView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [:name, :inserted_at, :updated_at]


end
