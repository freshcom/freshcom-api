defmodule BlueJetWeb.AccountResetControllerTest do
  use BlueJetWeb.ConnCase

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{ conn: conn }
  end

  # Create an account reset (internal)
  describe "POST /v1/account_resets" do
    test "without UAT", %{conn: conn} do
      conn = post(conn, "/v1/account_resets", %{
        "data" => %{
          "type" => "AccountReset"
        }
      })

      assert conn.status == 401
    end

    # TODO: This test causes error due to account reset uses
    # seperate process for deletion, find a better way to
    # test this
    # test "with UAT", %{conn: conn} do
    #   standard_user = create_standard_user()
    #   uat = get_uat(standard_user, mode: :test)

    #   conn = put_req_header(conn, "authorization", "Bearer #{uat}")
    #   conn = post(conn, "/v1/account_resets", %{
    #     "data" => %{
    #       "type" => "AccountReset"
    #     }
    #   })

    #   assert conn.status == 202
    # end
  end
end
