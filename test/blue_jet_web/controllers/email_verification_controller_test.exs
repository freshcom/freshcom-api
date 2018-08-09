defmodule BlueJetWeb.EmailVerificationControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper

  def create_email_verification_token(user) do
    {:ok, %{data: user}} = Identity.create_email_verification_token(%AccessRequest{
      fields: %{
        "user_id" => user.id
      },
      vas: %{ account_id: user.default_account_id, user_id: user.id }
    })

    user.email_verification_token
  end

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{conn: conn}
  end

  # Create a email verification
  # - Without PAT this endpoint only create verification for standard user (internal)
  # - With PAT this endpoint only create verification for managed user
  describe "POST /v1/email_verification" do
    test "without PAT", %{conn: conn} do
      user = create_standard_user()
      evt = create_email_verification_token(user)

      conn = post(conn, "/v1/email_verifications", %{
        "data" => %{
          "type" => "EmailVerification",
          "attributes" => %{
            "token" => evt
          }
        }
      })

      assert conn.status == 204
    end

    test "with PAT", %{conn: conn} do
      standard_user = create_standard_user()
      managed_user = create_managed_user(standard_user)
      pat = get_pat(standard_user)
      evt = create_email_verification_token(managed_user)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = post(conn, "/v1/email_verifications", %{
        "data" => %{
          "type" => "EmailVerification",
          "attributes" => %{
            "token" => evt
          }
        }
      })

      assert conn.status == 204
    end
  end
end
