defmodule BlueJet.Identity.AuthenticationTest do
  use BlueJet.DataCase
  import BlueJet.Identity.TestHelper

  alias BlueJet.Identity.Authentication

  def refresh_tfa_code(user) do
    BlueJet.Identity.Service.refresh_tfa_code(user)
  end

  describe "deserialize_scope/1" do
    test "with valid scope using abbreviation" do
      scope = Authentication.deserialize_scope("aid:test-test-test", %{ aid: :account_id })

      assert scope.account_id == "test-test-test"
    end

    test "with valid scope using full name" do
      scope = Authentication.deserialize_scope("account_id:test-test-test", %{ aid: :account_id })

      assert scope.account_id == "test-test-test"
    end

    test "with partially valid scope" do
      scope = Authentication.deserialize_scope("aid:test-test-test,ddd", %{ aid: :account_id })

      assert scope.account_id == "test-test-test"
    end
  end

  describe "create_token/1" do
    test "when using incorrect credentials and no scope" do
      {:error, result} = Authentication.create_token(%{
        "grant_type" => "password",
        "username" => "invalid",
        "password" => "invalid"
      })

      assert result.error == :invalid_grant
      assert result.error_description
    end

    test "when using standard user credentials and scope" do
      user = standard_user_fixture()

      {:error, result} = Authentication.create_token(%{
        "grant_type" => "password",
        "username" => user.username,
        "password" => "test1234",
        "scope" => "account_id:#{user.default_account.id}"
      })

      # When scope is provided, we should only create token for managed user
      assert result.error == :invalid_grant
      assert result.error_description
    end

    test "when using standard user credentials and no scope" do
      user = standard_user_fixture()

      {:ok, result} = Authentication.create_token(%{
        "grant_type" => "password",
        "username" => user.username,
        "password" => "test1234"
      })

      assert result.expires_in
      assert result.access_token
      assert result.refresh_token
      assert result.token_type
    end

    test "when using managed user credentials and no scope" do
      standard_user = standard_user_fixture()
      managed_user = managed_user_fixture(standard_user.default_account)

      {:error, result} = Authentication.create_token(%{
        "grant_type" => "password",
        "username" => managed_user.username,
        "password" => "test1234"
      })

      assert result.error == :invalid_grant
      assert result.error_description
    end

    test "when using managed user credentials and invalid scope" do
      standard_user = standard_user_fixture()
      managed_user = managed_user_fixture(standard_user.default_account)

      {:error, result} = Authentication.create_token(%{
        "grant_type" => "password",
        "username" => managed_user.username,
        "password" => "test1234",
        "scope" => "aid:#{UUID.generate()}"
      })

      assert result.error == :invalid_grant
      assert result.error_description
    end

    test "when using managed user credentials and valid scope" do
      standard_user = standard_user_fixture()
      managed_user = managed_user_fixture(standard_user.default_account)

      {:ok, result} = Authentication.create_token(%{
        "grant_type" => "password",
        "username" => managed_user.username,
        "password" => "test1234",
        "scope" => "aid:#{managed_user.account_id}"
      })

      assert result.expires_in
      assert result.access_token
      assert result.refresh_token
      assert result.token_type
    end

    test "when using incorrect refresh token" do
      {:error, result} = Authentication.create_token(%{
        "grant_type" => "refresh_token",
        "refresh_token" => UUID.generate()
      })

      assert result.error == :invalid_grant
      assert result.error_description
    end

    test "when using prt and no scope" do
      account = account_fixture()
      prt = get_prt(account)

      {:ok, result} = Authentication.create_token(%{
        "grant_type" => "refresh_token",
        "refresh_token" => prt
      })

      assert result.expires_in
      assert result.access_token
      assert result.refresh_token
      assert result.token_type
    end

    test "when using urt and no scope" do
      user = standard_user_fixture()
      urt = get_urt(user.id, user.default_account_id)
      {:ok, result} = Authentication.create_token(%{
        "grant_type" => "refresh_token",
        "refresh_token" => urt
      })

      assert result.expires_in
      assert result.access_token
      assert result.refresh_token
      assert result.token_type
    end

    test "when using urt and scope containing test account id" do
      user = standard_user_fixture()
      urt = get_urt(user.id, user.default_account_id)
      test_account_id = user.default_account.test_account_id
      urt_test = get_urt(user.id, test_account_id)

      {:ok, result} = Authentication.create_token(%{
        "grant_type" => "refresh_token",
        "refresh_token" => urt,
        "scope" => "account_id:#{test_account_id}"
      })

      assert result.expires_in
      assert result.access_token
      assert result.refresh_token == urt_test
      assert result.token_type
    end

    test "when standard user auth method is tfa_sms and no otp" do
      user = standard_user_fixture(%{
        auth_method: "tfa_sms",
        phone_number: "+1234567890"
      })

      EventHandlerMock
      |> expect(:handle_event, fn(name, data) ->
          assert name == "identity:user.tfa_code.create.success"
          assert data[:user].tfa_code

          {:ok, nil}
         end)

      {:error, result} = Authentication.create_token(%{
        "grant_type" => "password",
        "username" => user.username,
        "password" => "test1234"
      })

      assert result.error == :invalid_otp
      assert result.error_description
    end

    test "when standard user auth method is tfa_sms and invalid otp" do
      user =
        %{auth_method: "tfa_sms", phone_number: "+1234567890"}
        |> standard_user_fixture()
        |> refresh_tfa_code()

      {:error, result} = Authentication.create_token(%{
        "grant_type" => "password",
        "username" => user.username,
        "password" => "test1234",
        "otp" => "invalid"
      })

      assert result.error == :invalid_otp
      assert result.error_description
    end

    test "when standard user auth method is tfa_sms and valid otp" do
      user =
        %{auth_method: "tfa_sms", phone_number: "+1234567890"}
        |> standard_user_fixture()
        |> refresh_tfa_code()

      {:ok, result} = Authentication.create_token(%{
        "grant_type" => "password",
        "username" => user.username,
        "password" => "test1234",
        "otp" => user.tfa_code
      })

      assert result.expires_in
      assert result.access_token
      assert result.refresh_token
      assert result.token_type
    end

    test "when managed user auth method is tfa_sms and no otp" do
      standard_user = standard_user_fixture()
      user = managed_user_fixture(standard_user.default_account, %{
        auth_method: "tfa_sms",
        phone_number: "+1234567890"
      })

      EventHandlerMock
      |> expect(:handle_event, fn(name, data) ->
          assert name == "identity:user.tfa_code.create.success"
          assert data[:user].tfa_code

          {:ok, nil}
         end)

      {:error, result} = Authentication.create_token(%{
        "grant_type" => "password",
        "username" => user.username,
        "password" => "test1234",
        "scope" => "aid:#{standard_user.default_account.id}"
      })

      assert result.error == :invalid_otp
      assert result.error_description
    end

    test "when managed user auth method is tfa_sms and invalid otp" do
      standard_user = standard_user_fixture()
      user =
        standard_user.default_account
        |> managed_user_fixture(%{auth_method: "tfa_sms", phone_number: "+1234567890"})
        |> refresh_tfa_code()

      {:error, result} = Authentication.create_token(%{
        "grant_type" => "password",
        "username" => user.username,
        "password" => "test1234",
        "scope" => "aid:#{standard_user.default_account.id}",
        "otp" => "invalid"
      })

      assert result.error == :invalid_otp
      assert result.error_description
    end

    test "when managed user auth method is tfa_sms and valid otp" do
      standard_user = standard_user_fixture()
      user =
        standard_user.default_account
        |> managed_user_fixture(%{auth_method: "tfa_sms", phone_number: "+1234567890"})
        |> refresh_tfa_code()

      {:ok, result} = Authentication.create_token(%{
        "grant_type" => "password",
        "username" => user.username,
        "password" => "test1234",
        "scope" => "aid:#{standard_user.default_account.id}",
        "otp" => user.tfa_code
      })

      assert result.expires_in
      assert result.access_token
      assert result.refresh_token
      assert result.token_type
    end
  end
end
