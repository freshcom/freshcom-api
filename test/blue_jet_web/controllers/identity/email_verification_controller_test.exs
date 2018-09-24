defmodule BlueJetWeb.EmailVerificationControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{conn: conn}
  end

  # Create a email verification
  # - Without access token this endpoint only create verification for standard user (internal)
  # - With PAT this endpoint only create verification for managed user
  # - With UAT this endpoint create verification for both standard and managed user
  describe "POST /v1/email_verification" do
    test "without access token", %{conn: conn} do
      user = standard_user_fixture()

      conn = post(conn, "/v1/email_verifications", %{
        "data" => %{
          "type" => "EmailVerification",
          "attributes" => %{
            "token" => user.email_verification_token
          }
        }
      })

      assert conn.status == 204
    end

    @tag :focus
    test "with PAT", %{conn: conn} do
      standard_user = standard_user_fixture()
      managed_user = managed_user_fixture(standard_user.default_account)
      pat = get_pat(standard_user.default_account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = post(conn, "/v1/email_verifications", %{
        "data" => %{
          "type" => "EmailVerification",
          "attributes" => %{
            "token" => managed_user.email_verification_token
          }
        }
      })

      assert conn.status == 204
    end

    test "with UAT of managed user", %{conn: conn} do
      standard_user = standard_user_fixture()
      managed_user = managed_user_fixture(standard_user.default_account)
      uat = get_uat(managed_user.account, managed_user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/email_verifications", %{
        "data" => %{
          "type" => "EmailVerification",
          "attributes" => %{
            "token" => managed_user.email_verification_token
          }
        }
      })

      assert conn.status == 204
    end

    test "with UAT of standard user", %{conn: conn} do
      user = standard_user_fixture()
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/email_verifications", %{
        "data" => %{
          "type" => "EmailVerification",
          "attributes" => %{
            "token" => user.email_verification_token
          }
        }
      })

      assert conn.status == 204
    end
  end
end
