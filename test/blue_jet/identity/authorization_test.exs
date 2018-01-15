defmodule BlueJet.Identity.AuthorizationTest do
  use BlueJet.DataCase
  import BlueJet.Identity.TestHelper

  alias BlueJet.Identity.Account
  alias BlueJet.Identity.Authorization

  describe "authorize/2" do
    test "when using anonymous identity" do
      {:error, :role_not_allowed} = Authorization.authorize(%{}, "not_allowed")
      {:ok, data} = Authorization.authorize(%{}, "identity.create_user")

      assert data[:role] == "anonymous"
      assert data[:account] == nil
    end

    test "when using guest identity" do
      %{ vas: vas } = create_global_identity("guest")
      {:error, :role_not_allowed} = Authorization.authorize(vas, "not_allowed")
      {:ok, data} = Authorization.authorize(vas, "identity.get_account")

      assert data[:role] == "guest"
      assert data[:account].id == vas[:account_id]
    end

    test "when using customer identity" do
      %{ vas: vas } = create_global_identity("customer")
      {:error, :role_not_allowed} = Authorization.authorize(vas, "not_allowed")
      {:ok, data} = Authorization.authorize(vas, "identity.get_user")

      assert data[:role] == "customer"
      assert data[:account].id == vas[:account_id]
    end

    test "when using developer identity" do
      %{ vas: vas } = create_global_identity("developer")
      {:error, :role_not_allowed} = Authorization.authorize(vas, "not_allowed")
      {:ok, data} = Authorization.authorize(vas, "identity.get_refresh_token")

      assert data[:role] == "developer"
      assert data[:account].id == vas[:account_id]
    end

    test "when using live guest identity for test account" do
      %{ account: account } = create_global_identity("guest")
      test_account = Repo.insert!(%Account{
        mode: "test",
        name: account.name,
        live_account_id: account.id
      })

      {:error, :role_not_allowed} = Authorization.authorize(%{ account_id: test_account.id }, "not_allowed")
      {:ok, data} = Authorization.authorize(%{ account_id: test_account.id }, "identity.get_account")

      assert data[:role] == "guest"
      assert data[:account].id == test_account.id
    end

    test "when using live customer identity for test account" do
      %{ account: account, user: user } = create_global_identity("customer")
      test_account = Repo.insert!(%Account{
        mode: "test",
        name: account.name,
        live_account_id: account.id
      })
      vas = %{ account_id: test_account.id, user_id: user.id }

      {:error, :test_account_not_allowed} = Authorization.authorize(vas, "not_allowed")
      {:ok, data} = Authorization.authorize(vas, "identity.get_user")

      assert data[:role] == "customer"
      assert data[:account].id == test_account.id
    end

    test "when using live developer identity for test account" do
      %{ account: account, user: user } = create_global_identity("developer")
      test_account = Repo.insert!(%Account{
        mode: "test",
        name: account.name,
        live_account_id: account.id
      })
      vas = %{ account_id: test_account.id, user_id: user.id }

      {:error, :test_account_not_allowed} = Authorization.authorize(vas, "not_allowed")
      {:ok, data} = Authorization.authorize(vas, "identity.get_refresh_token")

      assert data[:role] == "developer"
      assert data[:account].id == test_account.id
    end
  end
end
