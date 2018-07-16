defmodule BlueJetWeb.PasswordControllerTest do
  use BlueJetWeb.ConnCase

  alias BlueJet.AccessRequest
  alias BlueJet.Identity
  alias BlueJet.Identity.RefreshToken

  def create_standard_user() do
    Identity.create_user(%AccessRequest{
      fields: %{
        "name" => Faker.Name.name(),
        "username" => "standard_user1@example.com",
        "email" => "standard_user1@example.com",
        "password" => "standard1234",
        "default_locale" => "en"
      }
    })
  end

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{conn: conn}
  end

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
      {:ok, %{data: user}} = create_standard_user()
      {:ok, %{data: user}} = Identity.create_password_reset_token(%AccessRequest{
        fields: %{"username" => user.username }
      })

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
      {:ok, %{data: user}} = create_standard_user()
      {:ok, %{data: user}} = Identity.create_password_reset_token(%AccessRequest{
        fields: %{"username" => user.username }
      })

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
      {:ok, %{data: %{id: gu_id, default_account_id: account_id}}} = create_standard_user()
      {:ok, %{data: user}} = Identity.create_user(%AccessRequest{
        fields: %{
          "name" => Faker.Name.name(),
          "username" => "managed_user1@example.com",
          "email" => "managed_user1@example.com",
          "password" => "managed1234",
          "role" => "developer"
        },
        vas: %{account_id: account_id, user_id: gu_id}
      })

      {:ok, %{data: user}} = Identity.create_password_reset_token(%AccessRequest{
        fields: %{"username" => user.username },
        vas: %{account_id: account_id, user_id: nil}
      })

      conn = patch(conn, "/v1/password", %{
        "data" => %{
          "type" => "Password",
          "attributes" => %{
            "resetToken" => user.password_reset_token,
            "value" => "test1234"
          }
        }
      })

      # Without PRT we only look for standard user's password reset token
      response = json_response(conn, 422)
      assert length(response["errors"]) == 1
    end
  end
end
