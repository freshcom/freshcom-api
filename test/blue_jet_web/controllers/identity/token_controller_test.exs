defmodule BlueJetWeb.TokenControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper

  setup do
    conn =
      build_conn()
      |> put_req_header("content-type", "application/x-www-form-urlencoded")

    {:ok, conn: conn}
  end

  # Create a token
  describe "POST /v1/token" do
    test "with invalid grant type", %{conn: conn} do
      conn = post(conn, "/v1/token", %{
        "grant_type" => "lol",
        "username" => "standard_user1@example.com",
        "password" => "standard1234"
      })

      response = json_response(conn, 400)

      assert response["error_description"]
      assert response["error"] == "unsupported_grant_type"
    end

    test "with missing required parameters", %{conn: conn} do
      conn = post(conn, "/v1/token", %{})

      response = json_response(conn, 400)

      assert response["error_description"]
      assert response["error"] == "invalid_request"
    end

    test "with invalid scope", %{conn: conn} do
      conn = post(conn, "/v1/token", %{
        "grant_type" => "password",
        "username" => "standard_user1@example.com",
        "password" => "standard1234",
        "scope" => "yoyoyo"
      })

      # Invalid scope should be ignored as if its not provided and not crash
      response = json_response(conn, 400)

      assert response["error_description"]
      assert response["error"] == "invalid_grant"
    end

    test "with invalid user credentials and no scope", %{conn: conn} do
      conn = post(conn, "/v1/token", %{
        "grant_type" => "password",
        "username" => "standard_user1@example.com",
        "password" => "standard1234"
      })

      response = json_response(conn, 400)

      assert response["error_description"]
      assert response["error"] == "invalid_grant"
    end

    test "with valid standard user credentials and invalid scope", %{conn: conn} do
      user = standard_user_fixture()

      conn = post(conn, "/v1/token", %{
        "grant_type" => "password",
        "username" => user.username,
        "password" => "test1234",
        "scope" => "aid:#{UUID.generate()}"
      })

      response = json_response(conn, 400)

      assert response["error_description"]
      assert response["error"] == "invalid_grant"
    end

    test "with valid standard user credentials and no scope", %{conn: conn} do
      user = standard_user_fixture()

      conn = post(conn, "/v1/token", %{
        "grant_type" => "password",
        "username" => user.username,
        "password" => "test1234"
      })

      response = json_response(conn, 200)

      assert response["access_token"]
      assert response["expires_in"]
      assert response["refresh_token"]
    end

    test "with valid standard user credentials and scope", %{conn: conn} do
      user = standard_user_fixture()

      conn = post(conn, "/v1/token", %{
        "grant_type" => "password",
        "username" => user.username,
        "password" => "test1234",
        "scope" => "aid:#{user.default_account_id}"
      })

      response = json_response(conn, 400)

      # Scope is provided we only create token for managed user
      assert response["error"] == "invalid_grant"
      assert response["error_description"]
    end

    test "with valid managed user credentials and invalid scope", %{conn: conn} do
      account = account_fixture()
      user = managed_user_fixture(account)

      conn = post(conn, "/v1/token", %{
        "grant_type" => "password",
        "username" => user.username,
        "password" => "test1234",
        "scope" => "aid:invalid"
      })

      response = json_response(conn, 400)

      assert response["error"] == "invalid_grant"
      assert response["error_description"]
    end

    test "with valid managed user credentials and no scope", %{conn: conn} do
      account = account_fixture()
      user = managed_user_fixture(account)

      conn = post(conn, "/v1/token", %{
        "grant_type" => "password",
        "username" => user.username,
        "password" => "test1234"
      })

      response = json_response(conn, 400)

      # When no scope is provided, we only create token for standard user
      assert response["error"] == "invalid_grant"
      assert response["error_description"]
    end

    test "with valid managed user credentials and valid scope", %{conn: conn} do
      account = account_fixture()
      user = managed_user_fixture(account)

      conn = post(conn, "/v1/token", %{
        "grant_type" => "password",
        "username" => user.username,
        "password" => "test1234",
        "scope" => "aid:#{user.default_account.id}"
      })

      response = json_response(conn, 200)

      assert response["access_token"]
      assert response["expires_in"]
      assert response["refresh_token"]
    end

    test "with valid customer user credentials and no scope", %{conn: conn} do
      account = account_fixture()
      user = managed_user_fixture(account, %{role: "customer"})

      conn = post(conn, "/v1/token", %{
        "grant_type" => "password",
        "username" => user.username,
        "password" => "test1234"
      })

      # Customer user should not be able to create token without setting scope
      response = json_response(conn, 400)

      assert response["error_description"]
      assert response["error"] == "invalid_grant"
    end

    test "with valid customer user credentials and valid scope", %{conn: conn} do
      account = account_fixture()
      user = managed_user_fixture(account, %{role: "customer"})

      conn = post(conn, "/v1/token", %{
        "grant_type" => "password",
        "username" => user.username,
        "password" => "test1234",
        "scope" => "aid:#{user.default_account.id}"
      })

      response = json_response(conn, 200)

      assert response["access_token"]
      assert response["expires_in"]
      assert response["refresh_token"]
    end

    test "with invalid refresh token", %{conn: conn} do
      conn = post(conn, "/v1/token", %{
        "grant_type" => "refresh_token",
        "refresh_token" => "invalid"
      })

      response = json_response(conn, 400)

      assert response["error_description"]
      assert response["error"] == "invalid_grant"
    end

    test "with valid refresh token and invalid scope", %{conn: conn} do
      user = standard_user_fixture()
      urt = get_urt(user.default_account, user)

      conn = post(conn, "/v1/token", %{
        "grant_type" => "refresh_token",
        "refresh_token" => urt,
        "scope" => "aid:invalid"
      })

      response = json_response(conn, 400)

      assert response["error_description"]
      assert response["error"] == "invalid_grant"
    end

    test "with valid refresh token and valid scope", %{conn: conn} do
      user = standard_user_fixture()
      urt = get_urt(user.default_account, user)

      conn = post(conn, "/v1/token", %{
        "grant_type" => "refresh_token",
        "refresh_token" => urt,
        "scope" => "aid:#{user.default_account.id}"
      })

      response = json_response(conn, 200)

      assert response["access_token"]
      assert response["expires_in"]
      assert response["refresh_token"]
    end

    test "with live refresh token and test account scope", %{conn: conn} do
      user = standard_user_fixture()
      urt = get_urt(user.default_account, user)
      test_account = user.default_account.test_account

      conn = post(conn, "/v1/token", %{
        "grant_type" => "refresh_token",
        "refresh_token" => urt,
        "scope" => "aid:#{test_account.id}"
      })

      response = json_response(conn, 200)

      assert response["access_token"]
      assert response["expires_in"]
      assert response["refresh_token"]
    end

    test "with test refresh token and live account scope", %{conn: conn} do
      user = standard_user_fixture()
      test_account = user.default_account.test_account
      urt_test = get_urt(test_account, user)

      conn = post(conn, "/v1/token", %{
        "grant_type" => "refresh_token",
        "refresh_token" => urt_test,
        "scope" => "aid:#{user.default_account.id}"
      })

      response = json_response(conn, 400)

      assert response["error_description"]
      assert response["error"] == "invalid_grant"
    end

    test "with valid refresh token and no scope", %{conn: conn} do
      user = standard_user_fixture()
      urt = get_urt(user.default_account, user)

      conn = post(conn, "/v1/token", %{
        "grant_type" => "refresh_token",
        "refresh_token" => urt
      })

      response = json_response(conn, 200)

      assert response["access_token"]
      assert response["expires_in"]
      assert response["refresh_token"]
    end

    test "with valid publishable refresh token and no scope", %{conn: conn} do
      user = standard_user_fixture()
      prt = get_prt(user.default_account)

      conn = post(conn, "/v1/token", %{
        "grant_type" => "refresh_token",
        "refresh_token" => prt
      })

      response = json_response(conn, 200)

      assert response["access_token"]
      assert response["expires_in"]
      assert response["refresh_token"]
    end
  end
end
