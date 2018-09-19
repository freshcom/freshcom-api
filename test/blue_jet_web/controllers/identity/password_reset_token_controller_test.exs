defmodule BlueJetWeb.PasswordResetTokenControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{conn: conn}
  end

  # Create a password reset token
  # - Without access token this endpoint only create the token for standard user (internal)
  # - With PAT this endpoint only create the token for managed user
  describe "POST /v1/password_reset_tokens" do
    test "without access token and given a non existing standard user's username", %{conn: conn} do
      account = account_fixture()
      user = managed_user_fixture(account)

      conn = post(conn, "/v1/password_reset_tokens", %{
        "data" => %{
          "type" => "PasswordResetToken",
          "attributes" => %{
            "username" => user.username
          }
        }
      })

      # Without a access token we only look for standard user to create the token
      response = json_response(conn, 422)
      assert length(response["errors"]) == 1
    end

    test "without access token and given a existing standard user's username", %{conn: conn} do
      user = standard_user_fixture()

      conn = post(conn, "/v1/password_reset_tokens", %{
        "data" => %{
          "type" => "PasswordResetToken",
          "attributes" => %{
            "username" => user.username
          }
        }
      })

      assert conn.status == 204
    end

    test "with PAT and given a existing managed user's username", %{conn: conn} do
      account = account_fixture()
      user = managed_user_fixture(account)
      pat = get_pat(account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = post(conn, "/v1/password_reset_tokens", %{
        "data" => %{
          "type" => "PasswordResetToken",
          "attributes" => %{
            "username" => user.username
          }
        }
      })

      assert conn.status == 204
    end

    test "with PAT and given a existing standard user's username that is a member of target account", %{conn: conn} do
      user = standard_user_fixture()
      pat = get_pat(user.default_account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = post(conn, "/v1/password_reset_tokens", %{
        "data" => %{
          "type" => "PasswordResetToken",
          "attributes" => %{
            "username" => user.username
          }
        }
      })

      # Using PAT we only look for managed user
      assert conn.status == 422
    end
  end
end
