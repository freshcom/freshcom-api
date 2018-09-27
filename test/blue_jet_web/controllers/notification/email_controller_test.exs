defmodule BlueJetWeb.EmailControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper
  import BlueJet.Notification.TestHelper

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{conn: conn}
  end

  # Retrieve a email
  describe "GET /v1/emails/:id" do
    test "without access token", %{conn: conn} do
      conn = get(conn, "/v1/emails/#{UUID.generate()}")

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      user = standard_user_fixture()
      pat = get_pat(user.default_account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = get(conn, "/v1/emails/#{UUID.generate()}")

      assert conn.status == 403
    end

    test "with UAT requesting a email of a different account", %{conn: conn} do
      user1 = standard_user_fixture()
      user2 = standard_user_fixture()
      email = email_fixture(user2.default_account)
      uat = get_uat(user1.default_account, user1)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/emails/#{email.id}")

      assert conn.status == 404
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      email = email_fixture(user.default_account)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/emails/#{email.id}")

      assert json_response(conn, 200)
    end
  end

  # List email
  describe "GET /v1/emails" do
    test "without access token", %{conn: conn} do
      conn = get(conn, "/v1/emails")

      assert conn.status == 401
    end

    test "with UAT", %{conn: conn} do
      user1 = standard_user_fixture()
      user2 = standard_user_fixture()

      email_fixture(user1.default_account)
      email_fixture(user1.default_account)
      email_fixture(user2.default_account)

      uat = get_uat(user1.default_account, user1)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/emails")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2
    end
  end
end
