defmodule BlueJetWeb.TokenControllerTest do
  use BlueJetWeb.ConnCase

  alias BlueJet.Identity.{Account, RefreshToken}

  def create_standard_user() do
    Identity.create_user(%AccessRequest{
      fields: %{
        "name" => Faker.Name.name(),
        "username" => "standard_user1@example.com",
        "email" => "standard_user1@example.com",
        "password" => "standard1234",
        "default_locale" => "en"
      }
    })
  end

  setup do
    conn =
      build_conn()
      |> put_req_header("content-type", "application/x-www-form-urlencoded")

    {:ok, conn: conn}
  end

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
      {:ok, _} = create_standard_user()

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
      {:ok, _} = create_standard_user()

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

    test "with valid standard user credentials and valid scope", %{conn: conn} do
      {:ok, %{ data: user }} = create_standard_user()

      conn = post(conn, "/v1/token", %{
        "grant_type" => "password",
        "username" => "standard_user1@example.com",
        "password" => "standard1234",
        "scope" => "aid:#{user.default_account_id}"
      })

      response = json_response(conn, 200)

      assert response["access_token"]
      assert response["expires_in"]
      assert response["refresh_token"]
    end

    test "with valid account user credentials and invalid scope", %{conn: conn} do
      {:ok, %{data: %{id: gu_id, default_account_id: account_id}}} = create_standard_user()

      {:ok, _} = Identity.create_user(%AccessRequest{
        fields: %{
          "name" => Faker.Name.name(),
          "username" => "managed_user1@example.com",
          "email" => "managed_user1@example.com",
          "password" => "managed1234",
          "role" => "developer",
          "default_locale" => "en"
        },
        vas: %{account_id: account_id, user_id: gu_id}
      })

      conn = post(conn, "/v1/token", %{
        "grant_type" => "password",
        "username" => "managed_user1@example.com",
        "password" => "managed1234",
        "scope" => "aid:invalid"
      })

      response = json_response(conn, 400)

      assert response["error_description"]
      assert response["error"] == "invalid_grant"
    end

    test "with valid account user credentials and no scope", %{conn: conn} do
      {:ok, %{data: %{id: gu_id, default_account_id: account_id}}} = create_standard_user()

      {:ok, _} = Identity.create_user(%AccessRequest{
        fields: %{
          "name" => Faker.Name.name(),
          "username" => "managed_user1@example.com",
          "email" => "managed_user1@example.com",
          "password" => "managed1234",
          "role" => "developer",
          "default_locale" => "en"
        },
        vas: %{account_id: account_id, user_id: gu_id}
      })

      conn = post(conn, "/v1/token", %{
        "grant_type" => "password",
        "username" => "managed_user1@example.com",
        "password" => "managed1234"
      })

      response = json_response(conn, 200)

      assert response["access_token"]
      assert response["expires_in"]
      assert response["refresh_token"]
    end

    test "with valid account user credentials and valid scope", %{conn: conn} do
      {:ok, %{data: %{id: gu_id, default_account_id: account_id}}} = create_standard_user()

      {:ok, _} = Identity.create_user(%AccessRequest{
        fields: %{
          "name" => Faker.Name.name(),
          "username" => "managed_user1@example.com",
          "email" => "managed_user1@example.com",
          "password" => "managed1234",
          "role" => "developer",
          "default_locale" => "en"
        },
        vas: %{account_id: account_id, user_id: gu_id}
      })

      conn = post(conn, "/v1/token", %{
        "grant_type" => "password",
        "username" => "managed_user1@example.com",
        "password" => "managed1234",
        "scope" => "aid:#{account_id}"
      })

      response = json_response(conn, 200)

      assert response["access_token"]
      assert response["expires_in"]
      assert response["refresh_token"]
    end

    test "with valid customer user credentials and no scope", %{conn: conn} do
      {:ok, %{data: %{id: gu_id, default_account_id: account_id}}} = create_standard_user()

      {:ok, _} = Identity.create_user(%AccessRequest{
        fields: %{
          "name" => Faker.Name.name(),
          "username" => "customer_user1@example.com",
          "email" => "customer_user1@example.com",
          "password" => "customer1234",
          "role" => "customer",
          "default_locale" => "en"
        },
        vas: %{account_id: account_id, user_id: gu_id}
      })

      conn = post(conn, "/v1/token", %{
        "grant_type" => "password",
        "username" => "customer_user1@example.com",
        "password" => "customer1234"
      })

      # Customer user should not be able to create token without setting scope
      response = json_response(conn, 400)

      assert response["error_description"]
      assert response["error"] == "invalid_grant"
    end

    test "with valid customer user credentials and valid scope", %{conn: conn} do
      {:ok, %{data: %{id: gu_id, default_account_id: account_id}}} = create_standard_user()

      {:ok, _} = Identity.create_user(%AccessRequest{
        fields: %{
          "name" => Faker.Name.name(),
          "username" => "customer_user1@example.com",
          "email" => "customer_user1@example.com",
          "password" => "customer1234",
          "role" => "customer",
          "default_locale" => "en"
        },
        vas: %{account_id: account_id, user_id: gu_id}
      })

      conn = post(conn, "/v1/token", %{
        "grant_type" => "password",
        "username" => "customer_user1@example.com",
        "password" => "customer1234",
        "scope" => "aid:#{account_id}"
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
      {:ok, %{data: %{id: user_id, default_account_id: account_id}}} = create_standard_user()
      %{ id: refresh_token } = Repo.get_by(RefreshToken, user_id: user_id, account_id: account_id)

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
      {:ok, %{data: %{id: user_id, default_account_id: account_id}}} = create_standard_user()
      %{ id: refresh_token } = Repo.get_by(RefreshToken, user_id: user_id, account_id: account_id)

      conn = post(conn, "/v1/token", %{
        "grant_type" => "refresh_token",
        "refresh_token" => "urt-live-#{refresh_token}",
        "scope" => "aid:#{account_id}"
      })

      response = json_response(conn, 200)

      assert response["access_token"]
      assert response["expires_in"]
      assert response["refresh_token"]
    end

    test "with live refresh token and test account scope", %{conn: conn} do
      {:ok, %{data: %{id: user_id, default_account_id: live_account_id}}} = create_standard_user()
      %{ id: refresh_token } = Repo.get_by(RefreshToken, user_id: user_id, account_id: live_account_id)
      %{ id: test_account_id } = Repo.get_by(Account, mode: "test", live_account_id: live_account_id)

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
      {:ok, %{data: %{id: user_id, default_account_id: live_account_id}}} = create_standard_user()
      %{ id: test_account_id } = Repo.get_by(Account, mode: "test", live_account_id: live_account_id)
      %{ id: refresh_token } = Repo.get_by(RefreshToken, user_id: user_id, account_id: test_account_id)

      conn = post(conn, "/v1/token", %{
        "grant_type" => "refresh_token",
        "refresh_token" => "urt-test-#{refresh_token}",
        "scope" => "aid:#{live_account_id}"
      })

      response = json_response(conn, 400)

      assert response["error_description"]
      assert response["error"] == "invalid_grant"
    end

    test "with valid refresh token and no scope", %{conn: conn} do
      {:ok, %{data: %{id: user_id, default_account_id: account_id}}} = create_standard_user()
      %{ id: refresh_token } = Repo.get_by(RefreshToken, user_id: user_id, account_id: account_id)

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
      {:ok, %{data: %{default_account_id: account_id}}} = create_standard_user()
      %{ id: refresh_token } = Repo.get_by(RefreshToken.Query.publishable(), account_id: account_id)

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
