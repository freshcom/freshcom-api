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

    test "when using incorrect refresh token" do
      {:error, response} = Authentication.create_token(%{
        "grant_type" => "refresh_token",
        "refresh_token" => Ecto.UUID.generate()
      })

      assert response.error == :invalid_grant
      assert response.error_description
    end

    test "when using prt" do
      %{ prt: prt } = create_global_identity("administrator")
      {:ok, response} = Authentication.create_token(%{
        "grant_type" => "refresh_token",
        "refresh_token" => RefreshToken.get_prefixed_id(prt)
      })

      assert response.expires_in
      assert response.access_token
      assert response.refresh_token
      assert response.token_type
    end

    test "when using urt" do
      %{ urt: urt } = create_global_identity("administrator")
      {:ok, response} = Authentication.create_token(%{
        "grant_type" => "refresh_token",
        "refresh_token" => RefreshToken.get_prefixed_id(urt)
      })

      assert response.expires_in
      assert response.access_token
      assert response.refresh_token
      assert response.token_type
    end
  end
end
