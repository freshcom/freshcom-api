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
    test "without PAT", %{conn: conn} do
      conn = get(conn, "/v1/account")

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      standard_user = create_standard_user()
      pat = get_pat(standard_user)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = get(conn, "/v1/account")

      response = json_response(conn, 200)
      assert response["data"]["id"] == standard_user.default_account_id
    end
  end

  # Update an account
  describe "PATCH /v1/user" do
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
      standard_user = create_standard_user()
      uat = get_uat(standard_user)

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
      standard_user = create_standard_user()
      uat = get_uat(standard_user, mode: :test)

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
