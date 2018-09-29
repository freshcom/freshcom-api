defmodule BlueJetWeb.BalanceSettingsControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper
  import BlueJet.Balance.TestHelper

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{conn: conn}
  end

  # Retrieve balance settings
  describe "GET /v1/balance_settings" do
    test "without access token", %{conn: conn} do
      conn = get(conn, "/v1/balance_settings")

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      user = standard_user_fixture()
      pat = get_pat(user.default_account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = get(conn, "/v1/balance_settings")

      assert conn.status == 403
    end

    test "with UAT requesting a settings of a different account", %{conn: conn} do
      user1 = standard_user_fixture()
      user2 = standard_user_fixture()
      settings_fixture(user2.default_account)
      uat = get_uat(user1.default_account, user1)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/balance_settings")

      assert conn.status == 404
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      settings_fixture(user.default_account)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/balance_settings")

      assert json_response(conn, 200)
    end
  end

  # Update balance settings
  describe "PATCH /v1/balance_settings" do
    test "without access token", %{conn: conn} do
      conn = patch(conn, "/v1/balance_settings", %{
        "data" => %{
          "type" => "Settings",
          "attributes" => %{
            "stripeUserId" => Faker.String.base64(12)
          }
        }
      })

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      user = standard_user_fixture()
      pat = get_pat(user.default_account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = patch(conn, "/v1/balance_settings", %{
        "data" => %{
          "type" => "Settings",
          "attributes" => %{
            "stripeUserId" => Faker.String.base64(12)
          }
        }
      })

      assert conn.status == 403
    end

    test "with UAT requesting settings of a different account", %{conn: conn} do
      user1 = standard_user_fixture()
      user2 = standard_user_fixture()
      settings_fixture(user2.default_account)
      uat = get_uat(user1.default_account, user1)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/balance_settings", %{
        "data" => %{
          "type" => "Settings",
          "attributes" => %{
            "stripeUserId" => Faker.String.base64(12)
          }
        }
      })

      assert conn.status == 404
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      settings_fixture(user.default_account)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/balance_settings", %{
        "data" => %{
          "type" => "Settings",
          "attributes" => %{
            "stripeUserId" => Faker.String.base64(12)
          }
        }
      })

      assert json_response(conn, 200)
    end
  end
end
