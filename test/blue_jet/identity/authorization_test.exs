defmodule BlueJet.Identity.AuthorizationTest do
  use BlueJet.DataCase

  alias BlueJet.Repo
  alias BlueJet.Identity.{Account, AccountMembership, User, Authorization}

  describe "authorize_vas/2" do
    test "when using anonymous identity" do
      vas = %{}

      {:error, :role_not_allowed} = Authorization.authorize_vas(vas, "not_allowed")
      {:ok, data} = Authorization.authorize_vas(vas, "identity.create_user")

      assert data[:role] == "anonymous"
      assert data[:account] == nil
    end

    test "when using guest identity" do
      account = Repo.insert!(%Account{})
      vas = %{ account_id: account.id }

      {:error, :role_not_allowed} = Authorization.authorize_vas(vas, "not_allowed")
      {:ok, data} = Authorization.authorize_vas(vas, "identity.get_account")

      assert data[:role] == "guest"
      assert data[:account].id == vas[:account_id]
    end

    test "when using customer identity" do
      account = Repo.insert!(%Account{})
      user = Repo.insert!(%User{
        default_account_id: account.id,
        username: Faker.String.base64(5)
      })
      Repo.insert!(%AccountMembership{
        account_id: account.id,
        user_id: user.id,
        role: "customer"
      })
      vas = %{ account_id: account.id, user_id: user.id }

      {:error, :role_not_allowed} = Authorization.authorize_vas(vas, "not_allowed")
      {:ok, data} = Authorization.authorize_vas(vas, "identity.get_user")

      assert data[:role] == "customer"
      assert data[:account].id == vas[:account_id]
    end

    test "when using developer identity" do
      account = Repo.insert!(%Account{})
      user = Repo.insert!(%User{
        default_account_id: account.id,
        username: Faker.String.base64(5)
      })
      Repo.insert!(%AccountMembership{
        account_id: account.id,
        user_id: user.id,
        role: "developer"
      })
      vas = %{ account_id: account.id, user_id: user.id }

      {:error, :role_not_allowed} = Authorization.authorize_vas(vas, "not_allowed")
      {:ok, data} = Authorization.authorize_vas(vas, "identity.get_refresh_token")

      assert data[:role] == "developer"
      assert data[:account].id == vas[:account_id]
    end

    test "when using live guest identity for test account" do
      account = Repo.insert!(%Account{})
      test_account = Repo.insert!(%Account{
        mode: "test",
        name: account.name,
        live_account_id: account.id
      })
      vas = %{ account_id: test_account.id }

      {:error, :role_not_allowed} = Authorization.authorize_vas(vas, "not_allowed")
      {:ok, data} = Authorization.authorize_vas(vas, "identity.get_account")

      assert data[:role] == "guest"
      assert data[:account].id == test_account.id
    end

    test "when using live customer identity for test account" do
      account = Repo.insert!(%Account{})
      user = Repo.insert!(%User{
        default_account_id: account.id,
        username: Faker.String.base64(5)
      })
      Repo.insert!(%AccountMembership{
        account_id: account.id,
        user_id: user.id,
        role: "customer"
      })
      test_account = Repo.insert!(%Account{
        mode: "test",
        name: account.name,
        live_account_id: account.id
      })
      vas = %{ account_id: test_account.id, user_id: user.id }

      {:error, :test_account_not_allowed} = Authorization.authorize_vas(vas, "not_allowed")
      {:ok, data} = Authorization.authorize_vas(vas, "identity.get_user")

      assert data[:role] == "customer"
      assert data[:account].id == test_account.id
    end

    test "when using live developer identity for test account" do
      account = Repo.insert!(%Account{})
      user = Repo.insert!(%User{
        default_account_id: account.id,
        username: Faker.String.base64(5)
      })
      Repo.insert!(%AccountMembership{
        account_id: account.id,
        user_id: user.id,
        role: "developer"
      })
      test_account = Repo.insert!(%Account{
        mode: "test",
        name: account.name,
        live_account_id: account.id
      })
      vas = %{ account_id: test_account.id, user_id: user.id }

      {:error, :test_account_not_allowed} = Authorization.authorize_vas(vas, "not_allowed")
      {:ok, data} = Authorization.authorize_vas(vas, "identity.get_refresh_token")

      assert data[:role] == "developer"
      assert data[:account].id == test_account.id
    end
  end
end
