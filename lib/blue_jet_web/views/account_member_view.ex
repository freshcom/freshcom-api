defmodule BlueJetWeb.AccountMemberView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [:role, :inserted_at, :updated_at]


end
