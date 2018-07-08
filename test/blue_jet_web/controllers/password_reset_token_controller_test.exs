defmodule BlueJetWeb.EmailTemplateControllerTest do
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

  describe "POST /v1/password_reset_tokens" do
    test "without PRT and given a non existing standard user's username", %{conn: conn} do
      {:ok, %{data: user}} = create_standard_user()
      {:ok, _} = Identity.create_user(%AccessRequest{
        fields: %{
          "name" => Faker.Name.name(),
          "username" => "managed_user1@example.com",
          "email" => "managed_user1@example.com",
          "password" => "managed1234",
          "role" => "developer"
        },
        vas: %{ account_id: user.default_account_id, user_id: user.id }
      })

      conn = post(conn, "/v1/password_reset_tokens", %{
        "data" => %{
          "type" => "PasswordResetToken",
          "attributes" => %{
            "username" => "managed_user1@example.com"
          }
        }
      })

      # Without a PRT we only look for standard user to create the token
      response = json_response(conn, 422)
      assert length(response["errors"]) == 1
    end

    test "without PRT and given a existing standard user's username", %{conn: conn} do
      {:ok, %{data: user}} = create_standard_user()

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

    test "with PRT and given a existing managed user's username", %{conn: conn} do
      {:ok, %{data: standard_user}} = create_standard_user()
      {:ok, %{data: managed_user}} = Identity.create_user(%AccessRequest{
        fields: %{
          "name" => Faker.Name.name(),
          "username" => "managed_user1@example.com",
          "email" => "managed_user1@example.com",
          "password" => "managed1234",
          "role" => "developer"
        },
        vas: %{ account_id: standard_user.default_account_id, user_id: standard_user.id }
      })

      %{ id: prt } = Repo.get_by(RefreshToken.Query.publishable(), account_id: standard_user.default_account_id)
      {:ok, %{data: %{access_token: pat}}} = Identity.create_token(%{
        fields: %{ grant_type: "refresh_token", refresh_token: prt }
      })

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

    test "with PRT and given a existing standard user's username", %{conn: conn} do
      {:ok, %{data: standard_user}} = create_standard_user()

      %{ id: prt } = Repo.get_by(RefreshToken.Query.publishable(), account_id: standard_user.default_account_id)
      {:ok, %{data: %{access_token: pat}}} = Identity.create_token(%{
        fields: %{ grant_type: "refresh_token", refresh_token: prt }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = post(conn, "/v1/password_reset_tokens", %{
        "data" => %{
          "type" => "PasswordResetToken",
          "attributes" => %{
            "username" => standard_user.username
          }
        }
      })

      assert conn.status == 204
    end

    test "with PRT and given a existing standard user's username that is not a member of that account", %{conn: conn} do
      {:ok, %{data: standard_user}} = create_standard_user()
      Identity.create_user(%AccessRequest{
        fields: %{
          "name" => Faker.Name.name(),
          "username" => "standard_user2@example.com",
          "email" => "standard_user2@example.com",
          "password" => "standard1234",
          "default_locale" => "en"
        }
      })

      %{ id: prt } = Repo.get_by(RefreshToken.Query.publishable(), account_id: standard_user.default_account_id)
      {:ok, %{data: %{access_token: pat}}} = Identity.create_token(%{
        fields: %{ grant_type: "refresh_token", refresh_token: prt }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = post(conn, "/v1/password_reset_tokens", %{
        "data" => %{
          "type" => "PasswordResetToken",
          "attributes" => %{
            "username" => "standard_user2@example.com"
          }
        }
      })

      assert conn.status == 422
    end
  end
end
