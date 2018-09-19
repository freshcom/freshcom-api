defmodule BlueJetWeb.PasswordControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{conn: conn}
  end

  # Update a password
  # - Without PAT this endpoint only update standard user's password (internal)
  # - With PAT this endpoint only update managed user's password
  describe "PATCH /v1/password" do
    test "given invalid password reset token", %{conn: conn} do
      conn = patch(conn, "/v1/password?resetToken=invalidToken", %{
        "data" => %{
          "type" => "Password",
          "attributes" => %{
            "value" => "test1234"
          }
        }
      })

      response = json_response(conn, 422)
      assert length(response["errors"]) == 1
    end

    test "given valid password reset token for standard user", %{conn: conn} do
      user = standard_user_fixture()
      token = password_reset_token_fixture(user)

      conn = patch(conn, "/v1/password?resetToken=#{token}", %{
        "data" => %{
          "type" => "Password",
          "attributes" => %{
            "value" => "test1234"
          }
        }
      })

      assert conn.status == 204
    end

    test "given valid password reset token for managed user", %{conn: conn} do
      managed_user =
        account_fixture()
        |> managed_user_fixture()

      token = password_reset_token_fixture(managed_user)

      conn = patch(conn, "/v1/password?resetToken=#{token}", %{
        "data" => %{
          "type" => "Password",
          "attributes" => %{
            "value" => "test1234"
          }
        }
      })

      # Without PAT we only look for standard user's password reset token
      response = json_response(conn, 422)
      assert length(response["errors"]) == 1
    end
  end

  describe "PATCH /v1/passwords/:id" do
    test "given standard user", %{conn: conn} do
      user = standard_user_fixture()
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/passwords/#{user.id}", %{
        "data" => %{
          "id" => user.id,
          "type" => "Password",
          "attributes" => %{
            "value" => "test1234"
          }
        }
      })

      assert conn.status == 404
    end

    test "given managed user", %{conn: conn} do
      account = account_fixture()
      managed_user = managed_user_fixture(account)
      uat = get_uat(managed_user.account, managed_user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/passwords/#{managed_user.id}", %{
        "data" => %{
          "id" => managed_user.id,
          "type" => "Password",
          "attributes" => %{
            "value" => "test1234"
          }
        }
      })

      assert conn.status == 204
    end
  end
end
