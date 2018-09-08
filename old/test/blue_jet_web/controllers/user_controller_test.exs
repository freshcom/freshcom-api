defmodule BlueJetWeb.UserControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper

  setup do
    conn = build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{ conn: conn }
  end

  describe "PATCH /v1/user" do
    test "with no access token", %{ conn: conn } do
      conn = patch(conn, "/v1/user", %{
        "data" => %{
          "type" => "User"
        }
      })

      assert conn.status == 401
    end

    test "with valid attrs", %{ conn: conn } do
      %{ user: user } = create_global_identity("customer")
      uat = create_access_token(user.username, "test1234")
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      new_first_name = Faker.Name.first_name()
      conn = patch(conn, "/v1/user", %{
        "data" => %{
          "id" => user.id,
          "type" => "User",
          "attributes": %{
            "firstName": new_first_name
          }
        }
      })

      assert conn.status == 200
      assert json_response(conn, 200)["data"]["attributes"]["firstName"] == new_first_name
    end

    test "with password but not providing current password", %{ conn: conn } do
      %{ user: user } = create_global_identity("customer")
      uat = create_access_token(user.username, "test1234")
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = patch(conn, "/v1/user", %{
        "data" => %{
          "id" => user.id,
          "type" => "User",
          "attributes": %{
            "password": "newpassword"
          }
        }
      })

      assert conn.status == 422
      assert json_response(conn, 422)["errors"]
    end

    test "with password and providing wrong current password", %{ conn: conn } do
      %{ user: user } = create_global_identity("customer")
      uat = create_access_token(user.username, "test1234")
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = patch(conn, "/v1/user", %{
        "data" => %{
          "id" => user.id,
          "type" => "User",
          "attributes": %{
            "currentPassword": "wrong",
            "password": "newpassword"
          }
        }
      })

      assert conn.status == 422
      assert json_response(conn, 422)["errors"]
    end

    test "with password and providing correct current password", %{ conn: conn } do
      %{ user: user } = create_global_identity("customer")
      uat = create_access_token(user.username, "test1234")
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = patch(conn, "/v1/user", %{
        "data" => %{
          "id" => user.id,
          "type" => "User",
          "attributes": %{
            "currentPassword": "test1234",
            "password": "newpassword"
          }
        }
      })

      assert conn.status == 200
    end
  end
end
