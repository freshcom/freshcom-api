defmodule BlueJetWeb.AccountControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{ conn: conn }
  end

  # Retrieve an account
  describe "GET /v1/account" do
    test "without access token", %{conn: conn} do
      conn = get(conn, "/v1/account")

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      user = standard_user_fixture()
      pat = get_pat(user.default_account)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{pat}")
        |> get("/v1/account")

      response = json_response(conn, 200)
      assert response["data"]["id"] == user.default_account.id
    end
  end

  # Update an account
  describe "PATCH /v1/account" do
    test "without UAT", %{conn: conn} do
      conn = patch(conn, "/v1/account", %{
        "data" => %{
          "type" => "Account",
          "attributes" => %{
            "name" => Faker.Name.name()
          }
        }
      })

      assert conn.status == 401
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      uat = get_uat(user.default_account, user)

      new_name = Faker.Name.name()
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/account", %{
        "data" => %{
          "type" => "Account",
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
      conn = patch(conn, "/v1/account", %{
        "data" => %{
          "type" => "Account",
          "attributes" => %{
            "name" => new_name
          }
        }
      })

      assert conn.status == 422
    end
  end
end
