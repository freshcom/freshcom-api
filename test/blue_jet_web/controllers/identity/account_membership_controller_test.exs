defmodule BlueJetWeb.AccountMembershipsControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{conn: conn}
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
      user = standard_user_fixture()
      managed_user_fixture(user.default_account)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/account_memberships")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2
    end

    test "with UAT and targeting user", %{conn: conn} do
      user = standard_user_fixture()
      account_fixture(user)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/account_memberships?target=user")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2
    end
  end

  # Update an account membership
  describe "PATCH /v1/account_memberships/:id" do
    test "without UAT", %{conn: conn} do
      conn = patch(conn, "/v1/account_memberships/#{UUID.generate()}", %{
        "data" => %{
          "type" => "AccountMembership"
        }
      })

      assert conn.status == 401
    end

    test "with UAT", %{conn: conn} do
      membership = account_membership_fixture()
      uat = get_uat(membership.account, membership.user)

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
