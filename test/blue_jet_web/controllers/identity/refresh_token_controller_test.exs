defmodule BlueJetWeb.RefreshTokenControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{conn: conn}
  end

  # Retrieve the publishable refresh token (internal)
  describe "GET /v1/refresh_token" do
    test "without UAT", %{conn: conn} do
      conn = get(conn, "/v1/refresh_token")

      assert conn.status == 401
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/refresh_token")

      response = json_response(conn, 200)
      assert response["data"]["attributes"]["prefixedId"]
    end
  end
end
