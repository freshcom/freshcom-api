defmodule BlueJet.IdentityTest do
  use BlueJet.DataCase

  alias BlueJet.Identity
  alias BlueJet.AccessRequest
  alias BlueJet.Identity.User
  alias BlueJet.Identity.Account

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
  end

  describe "get_account/1" do
    test "with vas" do
      %{ id: account_id } = Repo.insert!(%Account{})

      request = %AccessRequest{
        vas: %{ account_id: account_id }
      }

      {:ok, %{ data: account }} = Identity.get_account(request)

      assert account.id == account_id
    end
  end
end
