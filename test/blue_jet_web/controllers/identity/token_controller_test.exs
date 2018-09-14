defmodule BlueJetWeb.TokenControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper

  alias BlueJet.Identity.{Account, RefreshToken}

  def get_prt(user) do
    %{ id: prt } = Repo.get_by(RefreshToken.Query.publishable(), account_id: user.default_account_id)

    prt
  end

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
      create_standard_user()

      conn = post(conn, "/v1/token", %{
        "grant_type" => "password",
        "username" => "standard_user1@example.com",
        "password" => "standard1234",
        "scope" => "aid:#{Ecto.UUID.generate()}"
      })

      response = json_response(conn, 400)

      assert response["error_description"]
      assert response["error"] == "invalid_grant"
    end

    test "with valid standard user credentials and no scope", %{conn: conn} do
      create_standard_user()

      conn = post(conn, "/v1/token", %{
        "grant_type" => "password",
        "username" => "standard_user1@example.com",
        "password" => "standard1234"
      })

      response = json_response(conn, 200)

      assert response["access_token"]
      assert response["expires_in"]
      assert response["refresh_token"]
    end

    test "with valid standard user credentials and scope", %{conn: conn} do
      user = create_standard_user()

      conn = post(conn, "/v1/token", %{
        "grant_type" => "password",
        "username" => "standard_user1@example.com",
        "password" => "standard1234",
        "scope" => "aid:#{user.default_account_id}"
      })

      response = json_response(conn, 400)

      # Scope is provided we only create token for managed user
      assert response["error"] == "invalid_grant"
      assert response["error_description"]
    end

    test "with valid managed user credentials and invalid scope", %{conn: conn} do
      standard_user = create_standard_user()
      managed_user = create_managed_user(standard_user)

      conn = post(conn, "/v1/token", %{
        "grant_type" => "password",
        "username" => managed_user.username,
        "password" => "managed1234",
        "scope" => "aid:invalid"
      })

      response = json_response(conn, 400)

      assert response["error"] == "invalid_grant"
      assert response["error_description"]
    end

    test "with valid managed user credentials and no scope", %{conn: conn} do
      standard_user = create_standard_user()
      managed_user = create_managed_user(standard_user)

      conn = post(conn, "/v1/token", %{
        "grant_type" => "password",
        "username" => managed_user.username,
        "password" => "managed1234"
      })

      response = json_response(conn, 400)

      # When no scope is provided, we only create token for standard user
      assert response["error"] == "invalid_grant"
      assert response["error_description"]
    end

    test "with valid managed user credentials and valid scope", %{conn: conn} do
      standard_user = create_standard_user()
      managed_user = create_managed_user(standard_user)

      conn = post(conn, "/v1/token", %{
        "grant_type" => "password",
        "username" => managed_user.username,
        "password" => "managed1234",
        "scope" => "aid:#{standard_user.default_account_id}"
      })

      response = json_response(conn, 200)

      assert response["access_token"]
      assert response["expires_in"]
      assert response["refresh_token"]
    end

    test "with valid customer user credentials and no scope", %{conn: conn} do
      standard_user = create_standard_user()
      managed_user = create_managed_user(standard_user, role: "customer")

      conn = post(conn, "/v1/token", %{
        "grant_type" => "password",
        "username" => managed_user.username,
        "password" => "managed1234"
      })

      # Customer user should not be able to create token without setting scope
      response = json_response(conn, 400)

      assert response["error_description"]
      assert response["error"] == "invalid_grant"
    end

    test "with valid customer user credentials and valid scope", %{conn: conn} do
      standard_user = create_standard_user()
      managed_user = create_managed_user(standard_user, role: "customer")

      conn = post(conn, "/v1/token", %{
        "grant_type" => "password",
        "username" => managed_user.username,
        "password" => "managed1234",
        "scope" => "aid:#{standard_user.default_account_id}"
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
      standard_user = create_standard_user()
      refresh_token = get_urt(standard_user)

      conn = post(conn, "/v1/token", %{
        "grant_type" => "refresh_token",
        "refresh_token" => "urt-live-#{refresh_token}",
        "scope" => "aid:invalid"
      })

      response = json_response(conn, 400)

      assert response["error_description"]
      assert response["error"] == "invalid_grant"
    end

    test "with valid refresh token and valid scope", %{conn: conn} do
      standard_user = create_standard_user()
      refresh_token = get_urt(standard_user)

      conn = post(conn, "/v1/token", %{
        "grant_type" => "refresh_token",
        "refresh_token" => "urt-live-#{refresh_token}",
        "scope" => "aid:#{standard_user.default_account_id}"
      })

      response = json_response(conn, 200)

      assert response["access_token"]
      assert response["expires_in"]
      assert response["refresh_token"]
    end

    test "with live refresh token and test account scope", %{conn: conn} do
      standard_user = create_standard_user()
      refresh_token = get_urt(standard_user)
      %{ id: test_account_id } = Repo.get_by(Account, mode: "test", live_account_id: standard_user.default_account_id)

      conn = post(conn, "/v1/token", %{
        "grant_type" => "refresh_token",
        "refresh_token" => "urt-live-#{refresh_token}",
        "scope" => "aid:#{test_account_id}"
      })

      response = json_response(conn, 200)

      assert response["access_token"]
      assert response["expires_in"]
      assert response["refresh_token"]
    end

    test "with test refresh token and live account scope", %{conn: conn} do
      standard_user = create_standard_user()
      refresh_token = get_urt(standard_user, mode: :test)

      conn = post(conn, "/v1/token", %{
        "grant_type" => "refresh_token",
        "refresh_token" => "urt-test-#{refresh_token}",
        "scope" => "aid:#{standard_user.default_account_id}"
      })

      response = json_response(conn, 400)

      assert response["error_description"]
      assert response["error"] == "invalid_grant"
    end

    test "with valid refresh token and no scope", %{conn: conn} do
      standard_user = create_standard_user()
      refresh_token = get_urt(standard_user)

      conn = post(conn, "/v1/token", %{
        "grant_type" => "refresh_token",
        "refresh_token" => "urt-live-#{refresh_token}"
      })

      response = json_response(conn, 200)

      assert response["access_token"]
      assert response["expires_in"]
      assert response["refresh_token"]
    end

    test "with valid publishable refresh token and no scope", %{conn: conn} do
      standard_user = create_standard_user()
      refresh_token = get_prt(standard_user)

      conn = post(conn, "/v1/token", %{
        "grant_type" => "refresh_token",
        "refresh_token" => "prt-live-#{refresh_token}"
      })

      response = json_response(conn, 200)

      assert response["access_token"]
      assert response["expires_in"]
      assert response["refresh_token"]
    end
  end
end
