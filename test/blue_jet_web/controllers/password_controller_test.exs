defmodule BlueJetWeb.PasswordControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper

  alias BlueJet.AccessRequest
  alias BlueJet.Identity

  def create_password_reset_token(user) do
    if user.account_id do
      {:ok, %{data: user}} = Identity.create_password_reset_token(%AccessRequest{
        fields: %{"username" => user.username },
        vas: %{account_id: user.account_id, user_id: nil}
      })

      user
    else
      {:ok, %{data: user}} = Identity.create_password_reset_token(%AccessRequest{
        fields: %{"username" => user.username }
      })

      user
    end
  end

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{conn: conn}
  end

  # Update a password
  # - Without PAT this endpoint only update standard user's password
  # - With PAT this endpoint only update managed user's password
  describe "PATCH /v1/password" do
    test "given invalid password reset token", %{conn: conn} do
      conn = patch(conn, "/v1/password", %{
        "data" => %{
          "type" => "Password",
          "attributes" => %{
            "resetToken" => "invalid",
            "value" => "test1234"
          }
        }
      })

      response = json_response(conn, 422)
      assert length(response["errors"]) == 1
    end

    test "given password reset token that has expired", %{conn: conn} do
      user = create_standard_user()
      user = create_password_reset_token(user)

      user
      |> change(password_reset_token_expires_at: Timex.shift(Timex.now(), hours: -1))
      |> Repo.update()

      conn = patch(conn, "/v1/password", %{
        "data" => %{
          "type" => "Password",
          "attributes" => %{
            "resetToken" => user.password_reset_token,
            "value" => "test1234"
          }
        }
      })

      response = json_response(conn, 422)
      assert length(response["errors"]) == 1
    end

    test "given valid password reset token for standard user", %{conn: conn} do
      user = create_standard_user()
      user = create_password_reset_token(user)

      conn = patch(conn, "/v1/password", %{
        "data" => %{
          "type" => "Password",
          "attributes" => %{
            "resetToken" => user.password_reset_token,
            "value" => "test1234"
          }
        }
      })

      assert conn.status == 204
    end

    test "given valid password reset token for managed user", %{conn: conn} do
      standard_user = create_standard_user()
      managed_user = create_managed_user(standard_user)
      managed_user = create_password_reset_token(managed_user)

      conn = patch(conn, "/v1/password", %{
        "data" => %{
          "type" => "Password",
          "attributes" => %{
            "resetToken" => managed_user.password_reset_token,
            "value" => "test1234"
          }
        }
      })

      # Without PAT we only look for standard user's password reset token
      response = json_response(conn, 422)
      assert length(response["errors"]) == 1
    end
  end
end
