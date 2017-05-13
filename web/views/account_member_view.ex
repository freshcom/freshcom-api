defmodule BlueJet.AccountMemberView do
  use BlueJet.Web, :view
  use JaSerializer.PhoenixView

  attributes [:role, :inserted_at, :updated_at]
  

end
