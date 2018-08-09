defmodule BlueJetWeb.UserControllerTest do
  use BlueJetWeb.ConnCase

  alias BlueJet.Identity.{RefreshToken, AccountMembership}

  def create_standard_user(n \\ 1) do
    {:ok, %{data: standard_user}} = Identity.create_user(%AccessRequest{
      fields: %{
        "name" => Faker.Name.name(),
        "username" => "standard_user#{n}@example.com",
        "email" => "standard_user#{n}@example.com",
        "password" => "standard1234",
        "default_locale" => "en"
      }
    })

    standard_user
  end

  def create_managed_user(standard_user, n \\ 1) do
    {:ok, %{data: managed_user}} = Identity.create_user(%AccessRequest{
      fields: %{
        "name" => Faker.Name.name(),
        "username" => "managed_user#{n}@example.com",
        "email" => "managed_user#{n}@example.com",
        "password" => "managed1234",
        "role" => "developer"
      },
      vas: %{ account_id: standard_user.default_account_id, user_id: standard_user.id }
    })

    managed_user
  end

  def get_uat(user) do
    %{ id: urt } = Repo.get_by(RefreshToken, user_id: user.id, account_id: user.default_account_id)
    {:ok, %{data: %{access_token: uat}}} = Identity.create_token(%{
      fields: %{ grant_type: "refresh_token", refresh_token: urt }
    })

    uat
  end

  def join_account(account_id, user_id) do
    Repo.insert!(%AccountMembership{
      account_id: account_id,
      user_id: user_id,
      role: "developer"
    })
  end

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{ conn: conn }
  end

  # Create a user
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
      standard_user = create_standard_user()
      uat = get_uat(standard_user)

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

  # Retrieve a standard user
  describe "GET /v1/user" do
    test "without UAT", %{conn: conn} do
      conn = get(conn, "/v1/user")

      assert conn.status == 401
    end

    test "with UAT", %{conn: conn} do
      standard_user = create_standard_user()
      uat = get_uat(standard_user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/user")

      response = json_response(conn, 200)
      assert response["data"]["id"] == standard_user.id
    end
  end

  # Retrieve a managed user
  describe "GET /v1/users/:id" do
    test "without UAT", %{conn: conn} do
      conn = get(conn, "/v1/users/#{Ecto.UUID.generate()}")

      assert conn.status == 401
    end

    test "with UAT targeting a standard user", %{conn: conn} do
      standard_user1 = create_standard_user()
      standard_user2 = create_standard_user(2)
      join_account(standard_user1.default_account_id, standard_user2.id)
      uat = get_uat(standard_user1)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/users/#{standard_user2.id}")

      # This endpoint should not expose standard user
      assert conn.status == 404
    end

    test "with UAT targeting a managed user", %{conn: conn} do
      standard_user = create_standard_user()
      managed_user = create_managed_user(standard_user)
      uat = get_uat(standard_user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/users/#{managed_user.id}")

      response = json_response(conn, 200)
      assert response["data"]["id"] == managed_user.id
    end
  end

  # Update a standard user
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

    test "with UAT", %{conn: conn} do
      standard_user = create_standard_user()
      uat = get_uat(standard_user)

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
      standard_user1 = create_standard_user()
      standard_user2 = create_standard_user(2)
      join_account(standard_user1.default_account_id, standard_user2.id)
      uat = get_uat(standard_user1)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/users/#{standard_user2.id}", %{
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
      standard_user = create_standard_user()
      managed_user = create_managed_user(standard_user)
      uat = get_uat(standard_user)

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
  end

  # Delete a managed user
  describe "DELETE /v1/users/:id" do
    test "without UAT", %{conn: conn} do
      conn = delete(conn, "/v1/users/#{Ecto.UUID.generate()}")

      assert conn.status == 401
    end

    test "with UAT targeting a standard user", %{conn: conn} do
      standard_user1 = create_standard_user()
      standard_user2 = create_standard_user(2)
      join_account(standard_user1.default_account_id, standard_user2.id)
      uat = get_uat(standard_user1)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = delete(conn, "/v1/users/#{standard_user2.id}")

      # This endpoint should not expose standard user
      assert conn.status == 404
    end

    test "with UAT targeting a managed user", %{conn: conn} do
      standard_user = create_standard_user()
      managed_user = create_managed_user(standard_user)
      uat = get_uat(standard_user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = delete(conn, "/v1/users/#{managed_user.id}")

      assert conn.status == 204
    end
  end
end
