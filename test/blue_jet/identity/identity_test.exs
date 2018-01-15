defmodule BlueJet.Identity.IdentityTest do
  use BlueJet.DataCase
  import BlueJet.Identity.TestHelper

  alias BlueJet.Identity
  alias BlueJet.Identity.User
  alias BlueJet.AccessRequest

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

  # describe "get_user/1" do
  #   test "with customer vas" do
  #     %{ vas: vas, user: %{ id: user_id } } = create_global_identity("customer")

  #     request = %AccessRequest{
  #       vas: vas
  #     }

  #     {:ok, %{ data: user }} = Identity.get_user(request)

  #     assert user.id == user_id
  #   end

  #   test "with anonymous vas" do
  #     request = %AccessRequest{
  #       vas: %{}
  #     }

  #     {:error, :access_denied} = Identity.get_user(request)
  #   end
  # end

  # describe "update_account/1" do
  #   test "with administrator vas" do
  #     %{ vas: vas } = create_global_identity("administrator")

  #     new_name = Faker.Company.name()
  #     request = %AccessRequest{
  #       vas: vas,
  #       fields: %{ name: new_name }
  #     }

  #     {:ok, %{ data: account }} = Identity.update_account(request)

  #     assert account.name == new_name
  #   end

  #   test "with developer vas" do
  #     %{ vas: vas } = create_global_identity("developer")

  #     request = %AccessRequest{
  #       vas: vas
  #     }

  #     {:error, :access_denied} = Identity.update_account(request)
  #   end
  # end
end
