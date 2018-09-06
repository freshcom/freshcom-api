defmodule BlueJetWeb.EmailTemplateControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper

  alias BlueJet.ContextRequest
  alias BlueJet.Notification

  setup do
    conn = build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{ conn: conn }
  end

  describe "POST /v1/password_reset_tokens" do
    test "with invalid email", %{ conn: conn } do
      conn = post(conn, "/v1/password_reset_tokens", %{
        "data" => %{
          "type" => "PasswordResetToken",
          "attributes" => %{
            "email" => "user1@example.com"
          }
        }
      })

      assert conn.status == 404
    end

    test "with an account user", %{ conn: conn } do
      %{ user: user, account: account } = create_account_identity("customer")
      pat = create_publishable_access_token(account)
      conn = put_req_header(conn, "authorization", "Bearer #{pat}")

      conn = post(conn, "/v1/password_reset_tokens", %{
        "data" => %{
          "type" => "PasswordResetToken",
          "attributes" => %{
            "email" => user.email
          }
        }
      })

      assert conn.status == 202
    end

    test "with an global user", %{ conn: conn } do
      %{ user: user, account: account } = create_global_identity("administrator")

      conn = post(conn, "/v1/password_reset_tokens", %{
        "data" => %{
          "type" => "PasswordResetToken",
          "attributes" => %{
            "email" => user.email
          }
        }
      })

      assert conn.status == 202
    end
  end
end
