# defmodule BlueJet.Identity.IdentityTest do
#   use BlueJet.DataCase
#   import BlueJet.Identity.TestHelper

#   alias BlueJet.Identity
#   alias BlueJet.AccessRequest

#   describe "create_user/1" do
#     test "with no vas" do
#       request = %AccessRequest{
#         vas: %{},
#         fields: %{
#           "email" => Faker.Internet.email(),
#           "first_name" => Faker.Name.first_name(),
#           "last_name" => Faker.Name.last_name(),
#           "account_name" => Faker.Company.name(),
#           "password" => "test1234",
#           "default_locale" => "en"
#         }
#       }

#       {:ok, %{ data: user }} = Identity.create_user(request)
#       user = Repo.preload(user, [:refresh_tokens, :account_memberships, [default_account: :refresh_tokens]])

#       assert user.account_id == nil
#       assert user.default_account_id != nil
#       assert length(user.refresh_tokens) == 2
#       assert length(user.account_memberships) == 1
#       assert Enum.at(user.account_memberships, 0).role == "administrator"
#     end

#     test "with guest vas" do
#       %{ account: account, vas: vas } = create_global_identity("guest")

#       request = %AccessRequest{
#         vas: vas,
#         fields: %{
#           "email" => Faker.Internet.email(),
#           "first_name" => Faker.Name.first_name(),
#           "last_name" => Faker.Name.last_name(),
#           "password" => "test1234"
#         }
#       }

#       {:ok, %{ data: user }} = Identity.create_user(request)
#       user = Repo.preload(user, [:refresh_tokens])


#       assert length(user.refresh_tokens) == 1
#       assert user.account_id == account.id
#       assert user.default_account_id == account.id
#     end

#     test "with customer vas" do
#       %{ vas: vas } = create_global_identity("customer")

#       request = %AccessRequest{
#         vas: vas,
#         fields: %{
#           "email" => Faker.Internet.email(),
#           "first_name" => Faker.Name.first_name(),
#           "last_name" => Faker.Name.last_name(),
#           "password" => "test1234"
#         }
#       }

#       {:error, :access_denied} = Identity.create_user(request)
#     end
#   end

#   describe "get_user/1" do
#     test "with customer vas" do
#       %{ vas: vas, user: %{ id: user_id } } = create_global_identity("customer")

#       request = %AccessRequest{
#         vas: vas
#       }

#       {:ok, %{ data: user }} = Identity.get_user(request)

#       assert user.id == user_id
#     end

#     test "with anonymous vas" do
#       request = %AccessRequest{
#         vas: %{}
#       }

#       {:error, :access_denied} = Identity.get_user(request)
#     end
#   end

#   describe "update_account/1" do
#     test "with administrator vas" do
#       %{ vas: vas } = create_global_identity("administrator")

#       new_name = Faker.Company.name()
#       request = %AccessRequest{
#         vas: vas,
#         fields: %{ name: new_name }
#       }

#       {:ok, %{ data: account }} = Identity.update_account(request)

#       assert account.name == new_name
#     end

#     test "with developer vas" do
#       %{ vas: vas } = create_global_identity("developer")

#       request = %AccessRequest{
#         vas: vas
#       }

#       {:error, :access_denied} = Identity.update_account(request)
#     end
#   end
# end
