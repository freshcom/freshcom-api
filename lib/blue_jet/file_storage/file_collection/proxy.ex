defmodule BlueJet.FileStorage.FileCollection.Proxy do
  use BlueJet, :proxy

  alias BlueJet.FileStorage.IdentityService

  def get_account(file) do
    file.account || IdentityService.get_account(file)
  end
end