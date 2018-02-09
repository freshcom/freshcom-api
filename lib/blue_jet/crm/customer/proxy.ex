defmodule BlueJet.Crm.Customer.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Crm.IdentityService

  def get_account(customer) do
    customer.account || IdentityService.get_account(customer)
  end

  def put_account(customer) do
    %{ customer | account: get_account(customer) }
  end

  def put(customer, _, _), do: customer
end