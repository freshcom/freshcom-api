defmodule BlueJet.Identity.AuthenticationTest do
  use BlueJet.ContextCase
  import BlueJet.Identity.TestHelper

  alias BlueJet.Identity.{Account, User, RefreshToken, AccountMembership}
  alias BlueJet.Identity.Authentication

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

    test "when using valid credentials without scope" do
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

    test "when using urt without scope" do
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

    test "when using urt with scope" do
      %{ urt: urt, account: account, user: user } = create_global_identity("administrator")
      test_account = Repo.insert!(%Account{
        mode: "test",
        name: account.name,
        live_account_id: account.id
      })
      test_refresh_token = Repo.insert!(%RefreshToken{
        account_id: test_account.id,
        user_id: user.id
      })

      {:ok, response} = Authentication.create_token(%{
        "grant_type" => "refresh_token",
        "refresh_token" => RefreshToken.get_prefixed_id(urt),
        "scope" => "account_id:#{test_account.id}"
      })

      assert response.expires_in
      assert response.access_token
      assert response.refresh_token == RefreshToken.get_prefixed_id(test_refresh_token)
      assert response.token_type
    end

    test "when user auth method is tfa_sms but otp is not provided in the header" do
      account = Repo.insert!(%Account{})
      user =
        %User{
          default_account_id: account.id,
          username: Faker.Internet.email(),
          auth_method: "tfa_sms",
          encrypted_password: User.encrypt_password("test1234")
        }
        |> User.put_encrypted_password()
        |> Repo.insert!()
      Repo.insert!(%AccountMembership{
        user_id: user.id,
        account_id: account.id,
        role: "administrator"
      })
      Repo.insert!(%RefreshToken{
        user_id: user.id,
        account_id: account.id
      })

      EventHandlerMock
      |> expect(:handle_event, fn(name, _) ->
          assert name == "identity.user.tfa_code.create.success"
          {:ok, nil}
         end)

      {:error, response} = Authentication.create_token(%{
        "grant_type" => "password",
        "username" => user.username,
        "password" => "test1234"
      })

      verify!()
      assert response.error == :invalid_otp
      assert response.error_description
    end
  end
end
