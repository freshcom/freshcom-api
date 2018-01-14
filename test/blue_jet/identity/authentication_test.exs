defmodule BlueJet.Identity.AuthenticationTest do
  use BlueJet.DataCase
  import BlueJet.Identity.TestHelper

  alias BlueJet.Identity.Account
  alias BlueJet.Identity.Authentication
  alias BlueJet.Identity.RefreshToken

  describe "deserialize_scope/1" do
    test "with valid scope" do
      scope = Authentication.deserialize_scope("account_id:test-test-test")

      assert scope.account_id == "test-test-test"
    end

    test "with partially valid scope" do
      scope = Authentication.deserialize_scope("account_id:test-test-test,ddd")

      assert scope.account_id == "test-test-test"
    end
  end

  describe "create_token/1" do
    test "when using incorrect credentials with no scope" do
      %{ user: user } = create_global_identity("administrator")

      {:error, response} = Authentication.create_token(%{
        "grant_type" => "password",
        "username" => "invalid",
        "password" => "invalid"
      })

      assert response.error == :invalid_grant
      assert response.error_description
    end

    test "when using valid credentials but invalid scope" do
      %{ user: user } = create_global_identity("administrator")
      account = Repo.insert!(%Account{
        name: Faker.Company.name()
      })

      {:error, response} = Authentication.create_token(%{
        "grant_type" => "password",
        "username" => user.username,
        "password" => "test1234",
        "scope" => "account_id:#{account.id}"
      })

      assert response.error == :invalid_grant
      assert response.error_description
    end

    test "when using valid credentials with no scope" do
      %{ user: user } = create_global_identity("administrator")

      {:ok, response} = Authentication.create_token(%{
        "grant_type" => "password",
        "username" => user.username,
        "password" => "test1234"
      })

      assert response.expires_in
      assert response.access_token
      assert response.refresh_token
      assert response.token_type
    end

    test "when using valid credentials with valid scope" do
      %{ user: user } = create_global_identity("administrator")

      {:ok, response} = Authentication.create_token(%{
        "grant_type" => "password",
        "username" => user.username,
        "password" => "test1234"
      })

      assert response.expires_in
      assert response.access_token
      assert response.refresh_token
      assert response.token_type
    end
  end

  # describe "create_token_by_password/2" do
  #   test "with valid user and password" do
  #     %{ user: user } = create_global_identity("administrator")
  #     refresh_token = Repo.insert!(%RefreshToken{
  #       user_id: user.id,
  #       account_id: user.default_account_id
  #     })
  #     {:ok, token} = Authentication.create_token_by_password(user, "test1234")

  #     assert token.access_token
  #     assert token.token_type
  #     assert token.expires_in
  #     assert token.refresh_token == "urt-live-" <> refresh_token.id
  #   end

  #   test "with invalid user" do
  #     {:error, %{ error: :invalid_grant }} = Authentication.create_token_by_password(nil, "test1234")
  #   end

  #   test "with invalid password" do
  #     %{ user: user } = create_global_identity("administrator")
  #     {:error, %{ error: :invalid_grant }} = Authentication.create_token_by_password(user, "invalid")
  #   end
  # end

  # describe "create_token_by_password/3" do
  #   test "with valid user and password" do
  #     %{ user: user, account: account } = create_global_identity("administrator")
  #     refresh_token = Repo.insert!(%RefreshToken{ user_id: user.id, account_id: account.id })
  #     {:ok, token} = Authentication.create_token_by_password(user, "test1234", account.id)

  #     assert token.access_token
  #     assert token.token_type
  #     assert token.expires_in
  #     assert token.refresh_token == "urt-live-" <> refresh_token.id
  #   end

  #   test "with invalid user" do
  #     {:error, %{ error: :invalid_grant }} = Authentication.create_token_by_password(nil, "test1234", Ecto.UUID.generate())
  #   end

  #   test "with invalid password" do
  #     %{ user: user } = create_global_identity("administrator")
  #     {:error, %{ error: :invalid_grant }} = Authentication.create_token_by_password(user, "invalid", Ecto.UUID.generate())
  #   end
  # end

  # describe "create_token_by_refresh_token/1" do
  #   test "with publishable refresh token" do
  #     %{ account: account } = create_global_identity("guest")
  #     rt = Repo.insert!(%RefreshToken{ account_id: account.id })

  #     {:ok, token} = Authentication.create_token_by_refresh_token(rt)

  #     assert token.access_token
  #     assert token.token_type
  #     assert token.expires_in
  #     assert token.refresh_token == "prt-live-" <> rt.id
  #   end

  #   test "with user refresh token" do
  #     %{ user: user, account: account } = create_global_identity("administrator")
  #     rt = Repo.insert!(%RefreshToken{ user_id: user.id, account_id: account.id })

  #     {:ok, token} = Authentication.create_token_by_refresh_token(rt)

  #     assert token.access_token
  #     assert token.token_type
  #     assert token.expires_in
  #     assert token.refresh_token == "urt-live-" <> rt.id
  #   end

  #   test "with nil refresh token" do
  #     {:error, %{ error: :invalid_grant }} = Authentication.create_token_by_refresh_token(nil)
  #   end
  # end
end
