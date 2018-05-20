defmodule BlueJet.Fulfillment.FulfillmentPackage.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Fulfillment.IdentityService

  def get_account(package) do
    package.account || IdentityService.get_account(package)
  end

  def put_account(package) do
    %{ package | account: get_account(package) }
  end

  def put(package, _, _), do: package
end