defmodule BlueJetWeb.AccountMembershipsControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{ conn: conn }
  end

  # List all account memberships
  # - Without any query params this endpoint returns all memberships of the
  # - target account
  # - With query params target=user this endpoint returns all memberships of
  # - the target user (internal)
  describe "GET /v1/account_memberships" do
    test "without UAT", %{conn: conn} do
      conn = get(conn, "/v1/account_memberships")

      assert conn.status == 401
    end

    test "with UAT", %{conn: conn} do
      standard_user1 = create_standard_user()
      standard_user2 = create_standard_user(n: 2)
      join_account(standard_user1.default_account_id, standard_user2.id)

      uat = get_uat(standard_user1)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/account_memberships")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2
    end

    test "with UAT and targeting user", %{conn: conn} do
      standard_user1 = create_standard_user()
      standard_user2 = create_standard_user(n: 2)
      join_account(standard_user2.default_account_id, standard_user1.id)

      uat = get_uat(standard_user1)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/account_memberships?target=user")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2
    end
  end

  # Update an account membership
  describe "PATCH /v1/account_memberships/:id" do
    test "without UAT", %{conn: conn} do
      conn = patch(conn, "/v1/account_memberships/#{Ecto.UUID.generate()}", %{
        "data" => %{
          "type" => "AccountMembership"
        }
      })

      assert conn.status == 401
    end

    test "with UAT", %{conn: conn} do
      standard_user1 = create_standard_user()
      standard_user2 = create_standard_user(n: 2)
      membership = join_account(standard_user1.default_account_id, standard_user2.id)

      uat = get_uat(standard_user1)
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = patch(conn, "/v1/account_memberships/#{membership.id}", %{
        "data" => %{
          "id" => membership.id,
          "type" => "AccountMembership",
          "attributes" => %{
            "role" => "developer"
          }
        }
      })

      response = json_response(conn, 200)
      assert response["data"]["attributes"]["role"] == "developer"
    end
  end
end
