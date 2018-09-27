defmodule BlueJetWeb.SMSControllerTest do
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

  # Retrieve a sms
  describe "GET /v1/sms/:id" do
    test "without access token", %{conn: conn} do
      conn = get(conn, "/v1/sms/#{UUID.generate()}")

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      user = standard_user_fixture()
      pat = get_pat(user.default_account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = get(conn, "/v1/sms/#{UUID.generate()}")

      assert conn.status == 403
    end

    test "with UAT requesting a sms of a different account", %{conn: conn} do
      user1 = standard_user_fixture()
      user2 = standard_user_fixture()
      sms = sms_fixture(user2.default_account)
      uat = get_uat(user1.default_account, user1)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/sms/#{sms.id}")

      assert conn.status == 404
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      sms = sms_fixture(user.default_account)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/sms/#{sms.id}")

      assert json_response(conn, 200)
    end
  end

  # List sms
  describe "GET /v1/sms" do
    test "without access token", %{conn: conn} do
      conn = get(conn, "/v1/sms")

      assert conn.status == 401
    end

    test "with UAT", %{conn: conn} do
      user1 = standard_user_fixture()
      user2 = standard_user_fixture()

      sms_fixture(user1.default_account)
      sms_fixture(user1.default_account)
      sms_fixture(user2.default_account)

      uat = get_uat(user1.default_account, user1)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/sms")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2
    end
  end
end
