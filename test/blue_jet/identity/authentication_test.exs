defmodule BlueJet.Identity.AuthenticationTest do
  use BlueJet.DataCase
  import BlueJet.Identity.TestHelper

  alias BlueJet.Identity.Authentication
  alias BlueJet.Identity.RefreshToken
  alias BlueJet.Identity.Account
  # alias BlueJet.Identity
  # alias BlueJet.Repo

  # setup do
  #   {_, %User{ id: user1_id, default_account_id: account1_id }} = Identity.create_user(%{
  #     fields: %{
  #       "first_name" => Faker.Name.first_name(),
  #       "last_name" => Faker.Name.last_name(),
  #       "email" => "user1@example.com",
  #       "password" => "test1234",
  #       "account_name" => Faker.Company.name()
  #     }
  #   })
  #   account1_rt = from(r in RefreshToken, where: r.account_id == ^account1_id and is_nil(r.user_id) and is_nil(r.customer_id)) |> Repo.one()
  #   user1_rt = Repo.get_by(RefreshToken, account_id: account1_id, user_id: user1_id)

  #   {:ok, %Customer{ id: customer1_id }} = Identity.create_customer(%{
  #     vas: %{ account_id: account1_id },
  #     fields: %{
  #       "first_name" => Faker.Name.first_name(),
  #       "last_name" => Faker.Name.last_name(),
  #       "email" => "customer1@example.com",
  #       "password" => "test1234"
  #     }
  #   })
  #   customer1_rt = Repo.get_by(RefreshToken, account_id: account1_id, customer_id: customer1_id)

  #   %{ account1_rt: account1_rt.id,
  #      user1_rt: user1_rt.id,
  #      account1_id: account1_id,
  #      user1_id: user1_id,
  #      customer1_rt: customer1_rt.id,
  #      customer1_id: customer1_id
  #   }
  # end

  describe "deserialize_scope/1" do
    test "with valid scope" do
      scope = Authentication.deserialize_scope("type:user,account_id:test-test-test")

      assert scope.type == "user"
      assert scope.account_id == "test-test-test"
    end

    test "with partially valid scope" do
      scope = Authentication.deserialize_scope("type:user,account_id:test-test-test,ddd")

      assert scope.type == "user"
      assert scope.account_id == "test-test-test"
    end
  end

  describe "create_storefront_token/1" do
    test "with valid refresh_token" do
      account = Repo.insert!(%Account{})
      refresh_token = Repo.insert!(%RefreshToken{ account_id: account.id })
      {:ok, token} = Authentication.create_storefront_token(refresh_token.id)

      assert token.access_token
      assert token.token_type
      assert token.expires_in
      assert token.refresh_token == refresh_token.id
    end

    test "with invalid refresh_token" do
      account = Repo.insert!(%Account{})
      Repo.insert!(%RefreshToken{ account_id: account.id })
      {:error, %{ error: :invalid_grant, error_description: _ }} = Authentication.create_storefront_token(Ecto.UUID.generate())
    end
  end

  describe "create_user_account_token/1" do
    test "with valid username, password and scope" do
      %{ account: account, user: user } = create_identity("customer")
      refresh_token = Repo.insert!(%RefreshToken{ user_id: user.id, account_id: account.id })

      {:ok, token} = Authentication.create_user_account_token(user.email, "test1234", account.id)

      assert token.access_token
      assert token.token_type
      assert token.expires_in
      assert token.refresh_token == refresh_token.id
    end

    test "with invalid username, password" do
      %{ account: account, user: user } = create_identity("customer")

      {:error, %{ error: :invalid_grant, error_description: _ }} = Authentication.create_user_account_token(user.email, "invalid", account.id)
    end

    test "with valid username and password but invalid scope" do
      %{ account: account, user: user } = create_identity("customer")

      {:error, %{ error: :invalid_scope, error_description: _ }} = Authentication.create_user_account_token(user.email, "test1234", account.id)
    end
  end

  # describe "create_token/1" do
  #   test "password for User Account Access Token" do

  #   end
  # end

  # describe "get_token/2" do
  #   test "with no credentials, no scope" do
  #     {:error, %{ error: error }} = Authentication.get_token(%{})

  #     assert error == :invalid_request
  #   end

  #   test "with valid Customer credential but invalid scope" do
  #     {:error, %{ error: error }} = Authentication.get_token(%{ username: "customer1@example.com", password: "test1234", scope: "type:customer" })

  #     assert error == :invalid_request
  #   end

  #   test "with valid Customer credential and scope", %{ account1_id: account1_id } do
  #     {:ok, token} = Authentication.get_token(%{ username: "customer1@example.com", password: "test1234", scope: "type:customer,account_id:#{account1_id}" })

  #     assert token.access_token
  #     assert token.token_type
  #     assert token.expires_in
  #     assert token.refresh_token
  #   end

  #   test "with valid User credential and scope with not account_id" do
  #     {:ok, token} = Authentication.get_token(%{ username: "user1@example.com", password: "test1234", scope: "type:user" })

  #     assert token.access_token
  #     assert token.token_type
  #     assert token.expires_in
  #     assert token.refresh_token
  #   end

  #   test "with valid User credential and scope with specific account_id", %{ account1_id: account1_id } do
  #     {:ok, token} = Authentication.get_token(%{ username: "user1@example.com", password: "test1234", scope: "type:user,account_id:#{account1_id}" })

  #     assert token.access_token
  #     assert token.token_type
  #     assert token.expires_in
  #     assert token.refresh_token
  #   end

  #   test "with empty Refresh Token" do
  #     {:error, %{ error: error }} = Authentication.get_token(%{ refresh_token: "" })
  #     assert error == :invalid_grant
  #   end

  #   test "with invalid Refresh Token" do
  #     {:error, %{ error: error }} = Authentication.get_token(%{ refresh_token: "invalid" })
  #     assert error == :invalid_grant
  #   end

  #   test "with valid Storefront Refresh Token", %{ account1_rt: account1_rt } do
  #     {:ok, token} = Authentication.get_token(%{ refresh_token: account1_rt })

  #     assert token.access_token
  #     assert token.token_type
  #     assert token.expires_in
  #     assert token.refresh_token
  #   end

  #   test "with valid Customer Refresh Token", %{ customer1_rt: customer1_rt } do
  #     {:ok, token} = Authentication.get_token(%{ refresh_token: customer1_rt })

  #     assert token.access_token
  #     assert token.token_type
  #     assert token.expires_in
  #     assert token.refresh_token
  #   end

  #   test "with valid User Refresh Token", %{ user1_rt: user1_rt } do
  #     {:ok, token} = Authentication.get_token(%{ refresh_token: user1_rt })

  #     assert token.access_token
  #     assert token.token_type
  #     assert token.expires_in
  #     assert token.refresh_token
  #   end
  # end
end
