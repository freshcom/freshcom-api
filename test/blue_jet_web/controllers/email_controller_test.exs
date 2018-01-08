defmodule BlueJetWeb.EmailControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper

  setup do
    conn = build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{ conn: conn }
  end

  describe "GET /v1/emails" do
    test "with no access token", %{ conn: conn } do
      conn = get(conn, "/v1/emails")

      assert conn.status == 401
    end

    test "with a valid request", %{ conn: conn } do
      %{ user: user } = create_identity("administrator")
      uat = create_access_token(user.username, "test1234")
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = get(conn, "/v1/emails")

      assert conn.status == 200
    end
  end
end
