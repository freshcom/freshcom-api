defmodule BlueJetWeb.PhoneVerificationCodeControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{conn: conn}
  end

  # Create a phone verification code
  describe "POST /v1/phone_verification_codes" do
    test "without access token", %{conn: conn} do
      conn = post(conn, "/v1/phone_verification_codes", %{
        "data" => %{
          "type" => "PhoneVerificationCode"
        }
      })

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      user = standard_user_fixture()
      pat = get_pat(user.default_account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = post(conn, "/v1/phone_verification_codes", %{
        "data" => %{
          "type" => "PhoneVerificationCode",
          "attributes" => %{
            "phoneNumber" => "+11234567890"
          }
        }
      })

      assert conn.status == 204
    end
  end
end
