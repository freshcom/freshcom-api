defmodule BlueJet.IdentityTest do
  use BlueJet.DataCase

  alias BlueJet.Identity
  alias BlueJet.AccessRequest
  alias BlueJet.Identity.User
  alias BlueJet.Identity.Account
  alias BlueJet.Identity.AccountMembership

  describe "create_user/1" do
    test "with no vas" do
      request = %AccessRequest{
        preloads: [:refresh_tokens, :account_memberships, [default_account: :refresh_tokens]],
        vas: %{},
        fields: %{
          email: Faker.Internet.email(),
          first_name: Faker.Name.first_name(),
          last_name: Faker.Name.last_name(),
          account_name: Faker.Company.name(),
          password: "test1234"
        }
      }

      {:ok, %{ data: user }} = Identity.create_user(request)

      assert user.account_id == nil
      assert user.default_account_id != nil
      assert length(user.default_account.refresh_tokens) == 2
      assert length(user.refresh_tokens) == 2
      assert length(user.account_memberships) == 1
      assert Enum.at(user.account_memberships, 0).role == "administrator"
    end

    test "with guest vas" do
      account = Repo.insert!(%Account{})

      request = %AccessRequest{
        preloads: [:refresh_tokens],
        vas: %{ account_id: account.id },
        fields: %{
          email: Faker.Internet.email(),
          first_name: Faker.Name.first_name(),
          last_name: Faker.Name.last_name(),
          password: "test1234"
        }
      }

      {:ok, %{ data: user }} = Identity.create_user(request)

      assert length(user.refresh_tokens) == 1
      assert user.account_id == account.id
      assert user.default_account_id == account.id
    end

    test "with customer vas" do
      user = Repo.insert!(%User{
        email: Faker.Internet.email(),
        first_name: Faker.Name.first_name(),
        last_name: Faker.Name.last_name(),
        password: "test1234"
      })
      account = Repo.insert!(%Account{})
      Repo.insert!(%AccountMembership{
        user_id: user.id,
        account_id: account.id,
        role: "customer"
      })

      request = %AccessRequest{
        preloads: [:refresh_tokens],
        vas: %{ account_id: account.id, user_id: user.id },
        fields: %{
          email: Faker.Internet.email(),
          first_name: Faker.Name.first_name(),
          last_name: Faker.Name.last_name(),
          password: "test1234"
        }
      }

      {:error, :access_denied} = Identity.create_user(request)
    end
  end

  describe "get_account/1" do
    test "with guest vas" do
      %{ id: account_id } = Repo.insert!(%Account{})

      request = %AccessRequest{
        vas: %{ account_id: account_id }
      }

      {:ok, %{ data: account }} = Identity.get_account(request)

      assert account.id == account_id
    end
  end

  describe "get_user/1" do
    test "with customer vas" do
      %{ id: user_id } = Repo.insert!(%User{
        email: Faker.Internet.email(),
        first_name: Faker.Name.first_name(),
        last_name: Faker.Name.last_name(),
        password: "test1234"
      })
      account = Repo.insert!(%Account{})
      Repo.insert!(%AccountMembership{
        user_id: user_id,
        account_id: account.id,
        role: "customer"
      })

      request = %AccessRequest{
        vas: %{ account_id: account.id, user_id: user_id }
      }

      {:ok, %{ data: user }} = Identity.get_user(request)

      assert user.id == user_id
    end

    test "with anonymous vas" do
      request = %AccessRequest{
        vas: %{}
      }

      {:error, :access_denied} = Identity.get_user(request)
    end
  end
end
