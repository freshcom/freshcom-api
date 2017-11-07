defmodule BlueJet.Identity.AuthenticationTest do
  use BlueJet.DataCase
  import BlueJet.Identity.TestHelper

  alias BlueJet.Identity.Authentication
  alias BlueJet.Identity.RefreshToken

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

  describe "create_token_by_password/2" do
    test "with valid user and password" do
      %{ user: user } = create_identity("administrator")
      refresh_token = Repo.insert!(%RefreshToken{ user_id: user.id, account_id: user.default_account_id })
      {:ok, token} = Authentication.create_token_by_password(user, "test1234")

      assert token.access_token
      assert token.token_type
      assert token.expires_in
      assert token.refresh_token == refresh_token.id
    end

    test "with invalid user" do
      {:error, %{ error: :invalid_grant }} = Authentication.create_token_by_password(nil, "test1234")
    end

    test "with invalid password" do
      %{ user: user } = create_identity("administrator")
      {:error, %{ error: :invalid_grant }} = Authentication.create_token_by_password(user, "invalid")
    end
  end

  describe "create_token_by_password/3" do
    test "with valid user and password" do
      %{ user: user, account: account } = create_identity("administrator")
      refresh_token = Repo.insert!(%RefreshToken{ user_id: user.id, account_id: account.id })
      {:ok, token} = Authentication.create_token_by_password(user, "test1234", account.id)

      assert token.access_token
      assert token.token_type
      assert token.expires_in
      assert token.refresh_token == refresh_token.id
    end

    test "with invalid user" do
      {:error, %{ error: :invalid_grant }} = Authentication.create_token_by_password(nil, "test1234", Ecto.UUID.generate())
    end

    test "with invalid password" do
      %{ user: user } = create_identity("administrator")
      {:error, %{ error: :invalid_grant }} = Authentication.create_token_by_password(user, "invalid", Ecto.UUID.generate())
    end
  end

  describe "create_token_by_refresh_token/1" do
    test "with Storefront Refresh Token" do
      refresh_token_id = Ecto.UUID.generate()
      {:ok, token} = Authentication.create_token_by_refresh_token(%RefreshToken{ id: refresh_token_id, account_id: Ecto.UUID.generate() })

      assert token.access_token
      assert token.token_type
      assert token.expires_in
      assert token.refresh_token == refresh_token_id
    end

    test "with User Account Refresh Token" do
      refresh_token_id = Ecto.UUID.generate()
      {:ok, token} = Authentication.create_token_by_refresh_token(%RefreshToken{ id: refresh_token_id, account_id: Ecto.UUID.generate(), user_id: Ecto.UUID.generate() })

      assert token.access_token
      assert token.token_type
      assert token.expires_in
      assert token.refresh_token == refresh_token_id
    end

    test "with User Global Refresh Token" do
      refresh_token_id = Ecto.UUID.generate()
      {:ok, token} = Authentication.create_token_by_refresh_token(%RefreshToken{ id: refresh_token_id, user_id: Ecto.UUID.generate() })

      assert token.access_token
      assert token.token_type
      assert token.expires_in
      assert token.refresh_token == refresh_token_id
    end

    test "with nil Refresh Token" do
      {:error, %{ error: :invalid_grant }} = Authentication.create_token_by_refresh_token(nil)
    end
  end
end
