defmodule BlueJetWeb.EmailVerificationTokenControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{conn: conn}
  end

  # Create a email verification token
  describe "POST /v1/email_verification_tokens" do
    test "without UAT", %{conn: conn} do
      conn = post(conn, "/v1/email_verification_tokens", %{
        "data" => %{
          "type" => "EmailVerificationToken"
        }
      })

      assert conn.status == 401
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/email_verification_tokens", %{
        "data" => %{
          "type" => "EmailVerificationToken",
          "relationships" => %{
            "user" => %{
              "data" => %{
                "id" => user.id,
                "type" => "User"
              }
            }
          }
        }
      })

      assert conn.status == 204
    end
  end
end
