defmodule BlueJetWeb.UserControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{ conn: conn }
  end

  # Create a user
  # - Without UAT this endpoint create a standard user (internal)
  # - With UAT this endpoint create a managed user
  describe "POST /v1/users" do
    test "with no attributes", %{conn: conn} do
      conn = post(conn, "/v1/users", %{
        "data" => %{
          "type" => "User"
        }
      })

      response = json_response(conn, 422)
      assert length(response["errors"]) == 3
    end

    test "without UAT should create standard user", %{conn: conn} do
      email = Faker.Internet.email()
      conn = post(conn, "/v1/users", %{
        "data" => %{
          "type" => "User",
          "attributes" => %{
            "name" => Faker.Name.name(),
            "username" => email,
            "email" => email,
            "password" => "standard123"
          }
        }
      })

      assert conn.status == 204
    end

    test "with UAT should create managed user", %{conn: conn} do
      user = standard_user_fixture()
      uat = get_uat(user.default_account, user)

      email = Faker.Internet.email()
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/users", %{
        "data" => %{
          "type" => "User",
          "attributes" => %{
            "name" => Faker.Name.name(),
            "username" => email,
            "email" => email,
            "password" => "standard123",
            "role" => "developer"
          }
        }
      })

      json_response(conn, 201)
    end
  end

  # Retrieve current user
  describe "GET /v1/user" do
    test "without UAT", %{conn: conn} do
      conn = get(conn, "/v1/user")

      assert conn.status == 401
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/user")

      response = json_response(conn, 200)
      assert response["data"]["id"] == user.id
    end

    test "with test UAT", %{conn: conn} do
      user = standard_user_fixture()
      test_account = user.default_account.test_account
      uat = get_uat(test_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/user")

      response = json_response(conn, 200)
      assert response["data"]["id"] == user.id
    end
  end

  # Retrieve a managed user
  describe "GET /v1/users/:id" do
    test "without UAT", %{conn: conn} do
      conn = get(conn, "/v1/users/#{Ecto.UUID.generate()}")

      assert conn.status == 401
    end

    test "with UAT targeting a standard user", %{conn: conn} do
      user1 = standard_user_fixture()
      user2 = standard_user_fixture()
      uat = get_uat(user1.default_account, user1)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/users/#{user2.id}")

      # This endpoint should not expose standard user
      assert conn.status == 404
    end

    test "with UAT targeting a managed user", %{conn: conn} do
      standard_user = standard_user_fixture()
      managed_user = managed_user_fixture(standard_user.default_account)
      uat = get_uat(standard_user.default_account, standard_user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/users/#{managed_user.id}")

      response = json_response(conn, 200)
      assert response["data"]["id"] == managed_user.id
    end

    test "with test UAT targeting a live managed user", %{conn: conn} do
      standard_user = standard_user_fixture()
      managed_user = managed_user_fixture(standard_user.default_account)
      test_account = standard_user.default_account.test_account
      uat = get_uat(test_account, standard_user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/users/#{managed_user.id}")

      assert conn.status == 404
    end
  end

  # Update current user
  describe "PATCH /v1/user" do
    test "without UAT", %{conn: conn} do
      conn = patch(conn, "/v1/user", %{
        "data" => %{
          "type" => "User",
          "attributes" => %{
            "name" => Faker.Name.name()
          }
        }
      })

      assert conn.status == 401
    end

    test "with UAT of standard user", %{conn: conn} do
      user = standard_user_fixture()
      uat = get_uat(user.default_account, user)

      new_name = Faker.Name.name()
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/user", %{
        "data" => %{
          "type" => "User",
          "attributes" => %{
            "name" => new_name
          }
        }
      })

      response = json_response(conn, 200)
      assert response["data"]["attributes"]["name"] == new_name
    end

    test "with UAT of managed user", %{conn: conn} do
      account = account_fixture()
      user = managed_user_fixture(account)
      uat = get_uat(account, user)

      new_name = Faker.Name.name()
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/user", %{
        "data" => %{
          "type" => "User",
          "attributes" => %{
            "name" => new_name
          }
        }
      })

      response = json_response(conn, 200)
      assert response["data"]["attributes"]["name"] == new_name
    end

    test "with test UAT", %{conn: conn} do
      user = standard_user_fixture()
      test_account = user.default_account.test_account
      uat = get_uat(test_account, user)

      new_name = Faker.Name.name()
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/user", %{
        "data" => %{
          "type" => "User",
          "attributes" => %{
            "name" => new_name
          }
        }
      })

      assert conn.status == 422
    end
  end

  # Update a managed user
  describe "PATCH /v1/users/:id" do
    test "without UAT", %{conn: conn} do
      conn = patch(conn, "/v1/users/#{Ecto.UUID.generate()}", %{
        "data" => %{
          "type" => "User",
          "attributes" => %{
            "name" => Faker.Name.name()
          }
        }
      })

      assert conn.status == 401
    end

    test "with UAT targeting a standard user", %{conn: conn} do
      user1 = standard_user_fixture()
      user2 = standard_user_fixture()
      uat = get_uat(user1.default_account, user1)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/users/#{user2.id}", %{
        "data" => %{
          "type" => "User",
          "attributes" => %{
            "name" => Faker.Name.name()
          }
        }
      })

      # This endpoint should not expose standard user
      assert conn.status == 404
    end

    test "with UAT targeting a managed user", %{conn: conn} do
      standard_user = standard_user_fixture()
      managed_user = managed_user_fixture(standard_user.default_account)
      uat = get_uat(standard_user.default_account, standard_user)

      new_name = Faker.Name.name()
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/users/#{managed_user.id}", %{
        "data" => %{
          "type" => "User",
          "attributes" => %{
            "name" => new_name
          }
        }
      })

      response = json_response(conn, 200)
      assert response["data"]["id"] == managed_user.id
      assert response["data"]["attributes"]["name"] == new_name
    end

    test "with test UAT targeting a live managed user", %{conn: conn} do
      standard_user = standard_user_fixture()
      managed_user = managed_user_fixture(standard_user.default_account)
      test_account = standard_user.default_account.test_account
      uat = get_uat(test_account, standard_user)

      new_name = Faker.Name.name()
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/users/#{managed_user.id}", %{
        "data" => %{
          "type" => "User",
          "attributes" => %{
            "name" => new_name
          }
        }
      })

      assert conn.status == 404
    end
  end

  # Delete a managed user
  describe "DELETE /v1/users/:id" do
    test "without UAT", %{conn: conn} do
      conn = delete(conn, "/v1/users/#{Ecto.UUID.generate()}")

      assert conn.status == 401
    end

    test "with UAT targeting a standard user", %{conn: conn} do
      user1 = standard_user_fixture()
      user2 = standard_user_fixture()
      uat = get_uat(user1.default_account, user1)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = delete(conn, "/v1/users/#{user2.id}")

      # This endpoint should not expose standard user
      assert conn.status == 404
    end

    test "with UAT targeting a managed user", %{conn: conn} do
      standard_user = standard_user_fixture()
      managed_user = managed_user_fixture(standard_user.default_account)
      uat = get_uat(standard_user.default_account, standard_user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = delete(conn, "/v1/users/#{managed_user.id}")

      assert conn.status == 204
    end

    test "with test UAT targeting a live managed user", %{conn: conn} do
      standard_user = standard_user_fixture()
      managed_user = managed_user_fixture(standard_user.default_account)
      test_account = standard_user.default_account.test_account
      uat = get_uat(test_account, standard_user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = delete(conn, "/v1/users/#{managed_user.id}")

      assert conn.status == 404
    end
  end
end
