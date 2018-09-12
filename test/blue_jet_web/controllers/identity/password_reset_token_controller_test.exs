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
      standard_user = create_standard_user()
      managed_user = create_managed_user(standard_user)

      conn = post(conn, "/v1/password_reset_tokens", %{
        "data" => %{
          "type" => "PasswordResetToken",
          "attributes" => %{
            "username" => managed_user.username
          }
        }
      })

      # Without a access token we only look for standard user to create the token
      response = json_response(conn, 422)
      assert length(response["errors"]) == 1
    end

    test "without access token and given a existing standard user's username", %{conn: conn} do
      user = create_standard_user()

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
      standard_user = create_standard_user()
      managed_user = create_managed_user(standard_user)
      pat = get_pat(standard_user)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = post(conn, "/v1/password_reset_tokens", %{
        "data" => %{
          "type" => "PasswordResetToken",
          "attributes" => %{
            "username" => managed_user.username
          }
        }
      })

      assert conn.status == 204
    end

    test "with PAT and given a existing standard user's username that is a member of target account", %{conn: conn} do
      standard_user = create_standard_user()
      pat = get_pat(standard_user)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = post(conn, "/v1/password_reset_tokens", %{
        "data" => %{
          "type" => "PasswordResetToken",
          "attributes" => %{
            "username" => standard_user.username
          }
        }
      })

      # Using PAT we only look for managed user
      assert conn.status == 422
    end
  end
end
