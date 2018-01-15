defmodule BlueJet.Identity.IdentityTest do
  use BlueJet.DataCase
  use Bamboo.Test

  import BlueJet.Identity.TestHelper

  alias BlueJet.AccessRequest

  alias BlueJet.Identity
  alias BlueJet.Identity.User
  alias BlueJet.Identity.Account
  alias BlueJet.Identity.AccountMembership
  alias BlueJet.Identity.RefreshToken

  describe "list_account/1" do
    test "when using guest identity" do
      %{ vas: vas } = create_global_identity("guest")

      {:error, error} =
        %AccessRequest{ vas: vas }
        |> Identity.list_account()

      assert error == :access_denied
    end

    test "when using customer identity" do
      %{ vas: vas, account: account } = create_global_identity("customer")
      {:ok, response} =
        %AccessRequest{ vas: vas }
        |> Identity.list_account()

      assert length(response.data) == 1
      assert response.meta.locale == account.default_locale
    end
  end

  describe "get_account/1" do
    test "when using anonymous identity" do
      {:error, error} =
        %AccessRequest{ vas: %{} }
        |> Identity.get_account()

      assert error == :access_denied
    end

    test "when using guest identity" do
      %{ vas: vas, account: account } = create_global_identity("guest")

      {:ok, response} =
        %AccessRequest{ vas: vas }
        |> Identity.get_account()

      assert response.data.id == vas[:account_id]
      assert response.meta.locale == account.default_locale
    end
  end

  describe "update_account/1" do
    test "when using customer identity" do
      %{ vas: vas } = create_global_identity("customer")

      {:error, error} =
        %AccessRequest{ vas: vas }
        |> Identity.update_account()

      assert error == :access_denied
    end

    test "when using administrator identity" do
      %{ vas: vas, account: account } = create_global_identity("administrator")
      test_account = Repo.insert!(%Account{
        mode: "test",
        name: account.name,
        live_account_id: account.id
      })
      new_name = Faker.Company.name()
      request = %AccessRequest{
        vas: vas,
        fields: %{
          name: new_name
        }
      }

      {:ok, response} = Identity.update_account(request)
      updated_account = Repo.get(Account, account.id)
      updated_test_account = Repo.get(Account, test_account.id)

      assert response.data.id == account.id
      assert response.data.name == new_name
      assert updated_account.name == new_name
      assert updated_test_account.name == new_name
    end
  end

  describe "create_password_reset_token/1" do
    test "when using anonymous identity for account identity" do
      %{ user: user } = create_account_identity("customer")

      {:ok, response} =
        %AccessRequest{ vas: %{}, fields: %{ "email" => user.email } }
        |> Identity.create_password_reset_token()

      updated_user = Repo.get!(User, user.id)

      refute updated_user.password_reset_token
      assert response.data == %{}
    end

    test "when using guest identity for account identity" do
      %{ user: user, account: account } = create_account_identity("customer")

      {:ok, response} =
        %AccessRequest{ vas: %{ account_id: account.id }, fields: %{ "email" => user.email } }
        |> Identity.create_password_reset_token()

      updated_user = Repo.get!(User, user.id)

      assert updated_user.password_reset_token
      assert response.data == %{}
    end

    test "when using anonymous identity for global identity" do
      %{ user: user } = create_global_identity("developer")

      {:ok, response} =
        %AccessRequest{ vas: %{ }, fields: %{ "email" => user.email } }
        |> Identity.create_password_reset_token()

      updated_user = Repo.get!(User, user.id)

      assert updated_user.password_reset_token
      assert response.data == %{}
    end

    test "when using guest identity for global identity" do
      %{ user: user, account: account } = create_global_identity("developer")

      {:ok, response} =
        %AccessRequest{ vas: %{ account_id: account.id }, fields: %{ "email" => user.email } }
        |> Identity.create_password_reset_token()

      updated_user = Repo.get!(User, user.id)

      refute updated_user.password_reset_token
      assert response.data == %{}
    end
  end

  describe "create_user/1" do
    test "when using anonymous identity" do
      request = %AccessRequest{
        vas: %{},
        fields: %{
          "username" => Faker.String.base64(5),
          "password" => "test1234",
          "account_name" => Faker.Company.name()
        }
      }

      {:ok, %{ data: user }} = Identity.create_user(request)
      user =
        User
        |> Repo.get!(user.id)
        |> Repo.preload([:refresh_tokens, :account_memberships])

      assert user.account_id == nil
      assert user.default_account_id != nil
      assert length(user.refresh_tokens) == 2
      assert length(user.account_memberships) == 1
      assert Enum.at(user.account_memberships, 0).role == "administrator"
    end

    test "when using guest identity" do
      %{ account: account, vas: vas } = create_global_identity("guest")

      request = %AccessRequest{
        vas: vas,
        fields: %{
          "username" => Faker.String.base64(5),
          "password" => "test1234"
        }
      }

      {:ok, %{ data: user }} = Identity.create_user(request)
      user =
        User
        |> Repo.get!(user.id)
        |> Repo.preload([:refresh_tokens, :account_memberships])

      assert user.account_id == account.id
      assert user.default_account_id == account.id
      assert length(user.refresh_tokens) == 1
      assert length(user.account_memberships) == 1
    end

    test "when using customer identity" do
      %{ vas: vas } = create_global_identity("customer")

      request = %AccessRequest{
        vas: vas
      }

      {:error, :access_denied} = Identity.create_user(request)
    end
  end

  describe "get_user/1" do
    test "when using guest identity" do
      %{ vas: vas } = create_global_identity("guest")
      {:error, error} = Identity.get_user(%AccessRequest{ vas: vas })

      assert error == :access_denied
    end

    test "when using customer identity" do
      %{ vas: vas, user: user } = create_account_identity("customer")
      {:ok, response} = Identity.get_user(%AccessRequest{ vas: vas })

      assert response.data.id == user.id
    end
  end

  describe "update_user/1" do
    test "when using guest identity" do
      %{ vas: vas } = create_global_identity("guest")
      {:error, error} = Identity.update_user(%AccessRequest{ vas: vas })

      assert error == :access_denied
    end

    test "when using customer identity" do
      %{ vas: vas, user: user } = create_account_identity("customer")
      new_username = Faker.String.base64(5)
      request = %AccessRequest{
        vas: vas,
        fields: %{
          "username" => new_username
        }
      }

      {:ok, response} = Identity.update_user(request)
      updated_user = Repo.get!(User, user.id)

      assert updated_user.username == new_username
      assert response.data.id == updated_user.id
      assert response.data.username == new_username
    end
  end

  describe "delete_user/1" do
    test "when using guest identity" do
      %{ vas: vas } = create_global_identity("guest")
      request = %AccessRequest{
        vas: vas,
        params: %{ "id" => Ecto.UUID.generate() }
      }

      {:error, error} = Identity.delete_user(request)

      assert error == :access_denied
    end

    test "when using customer identity trying to delete other user" do
      %{ vas: vas } = create_account_identity("customer")
      request = %AccessRequest{
        vas: vas,
        params: %{ "id" => Ecto.UUID.generate() }
      }

      {:error, error} = Identity.delete_user(request)

      assert error == :access_denied
    end

    test "when using customer identity deleting self" do
      %{ vas: vas, user: user } = create_account_identity("customer")
      request = %AccessRequest{
        vas: vas,
        params: %{ "id" => user.id }
      }

      {:ok, response} = Identity.delete_user(request)
      deleted_user = Repo.get(User, user.id)

      refute deleted_user
      assert response.data == %{}
    end

    test "when using administrator identity deleting global user" do
      %{ vas: vas } = create_global_identity("administrator")
      %{ user: user } = create_global_identity("administrator")
      Repo.insert!(%AccountMembership{ account_id: vas[:account_id], user_id: user.id })

      request = %AccessRequest{
        vas: vas,
        params: %{ "id" => user.id }
      }

      {:error, error} = Identity.delete_user(request)

      assert error == :not_found
    end

    test "when using administrator identity deleting account user" do
      %{ vas: vas, account: account } = create_global_identity("administrator")
      %{ user: user } = create_account_identity("customer", account)
      request = %AccessRequest{
        vas: vas,
        params: %{ "id" => user.id }
      }

      {:ok, response} = Identity.delete_user(request)
      deleted_user = Repo.get(User, user.id)

      refute deleted_user
      assert response.data == %{}
    end
  end

  describe "get_refresh_token/1" do
    test "when using customer identity" do
      %{ vas: vas } = create_global_identity("customer")

      {:error, error} = Identity.get_refresh_token(%AccessRequest{ vas: vas })

      assert error == :access_denied
    end

    test "when using developer identity" do
      %{ vas: vas, prt: prt } = create_global_identity("developer")

      {:ok, response} = Identity.get_refresh_token(%AccessRequest{ vas: vas })

      assert response.data.id == prt.id
      assert response.data.prefixed_id == RefreshToken.get_prefixed_id(prt)
    end
  end
end
