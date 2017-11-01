defmodule BlueJetWeb.AccountView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [:name, :stripe_user_id, :inserted_at, :updated_at]


end
