defmodule BlueJet.Crm.CustomerTest do
  use BlueJet.DataCase

  import Mox

  alias BlueJet.Identity.Account
  alias BlueJet.Crm.Customer

  describe "schema" do
    test "when account is deleted customer is automatically deleted" do
      account = Repo.insert!(%Account{})
      customer = Repo.insert!(%Customer{
        account_id: account.id
      })
      Repo.delete!(account)

      refute Repo.get(Customer, customer.id)
    end
  end
end
