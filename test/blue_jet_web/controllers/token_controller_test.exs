defmodule BlueJetWeb.TokenControllerTest do
  use BlueJetWeb.ConnCase

  alias BlueJet.Identity.User
  alias BlueJet.Identity.RefreshToken

  setup do
    conn = build_conn()
      |> put_req_header("content-type", "application/x-www-form-urlencoded")

    {_, %User{ default_account_id: account1_id }} = Identity.create_user(%{
      fields: %{
        "first_name" => Faker.Name.first_name(),
        "last_name" => Faker.Name.last_name(),
        "email" => "user1@example.com",
        "password" => "test1234",
        "account_name" => Faker.Company.name()
      }
    })
    srt1 = from(r in RefreshToken, where: r.account_id == ^account1_id and is_nil(r.user_id) and is_nil(r.customer_id)) |> Repo.one()

    {:ok, conn: conn, account1_id: account1_id, srt1: srt1.id }
  end

  describe "POST /v1/token" do
    test "with User credentials", %{conn: conn} do
      conn = post(conn, token_path(conn, :create), %{
        "grant_type" => "password",
        "username" => "user1@example.com",
        "password" => "test1234",
        "scope" => "type:user"
      })

      assert json_response(conn, 200)["access_token"]
      assert json_response(conn, 200)["expires_in"]
      assert json_response(conn, 200)["refresh_token"]
    end

    test "with Customer credentials", %{conn: conn, account1_id: account1_id } do
      email = "customer1@example.com"
      password = "test1234"
      {:ok, _} = Identity.create_customer(%{
        vas: %{ account_id: account1_id },
        fields: %{
          "first_name" => Faker.Name.first_name(),
          "last_name" => Faker.Name.last_name(),
          "email" => email,
          "password" => password
        }
      })

      conn = post(conn, token_path(conn, :create), %{
        "grant_type" => "password",
        "username" => email,
        "password" => password,
        "scope" => "type:customer,account_id:#{account1_id}"
      })

      assert json_response(conn, 200)["access_token"]
      assert json_response(conn, 200)["expires_in"]
      assert json_response(conn, 200)["refresh_token"]
    end

    test "with Storefront Refresh Token", %{conn: conn, srt1: srt1 } do
      conn = post(conn, token_path(conn, :create), %{
        "grant_type" => "refresh_token",
        "refresh_token" => srt1
      })

      assert json_response(conn, 200)["access_token"]
      assert json_response(conn, 200)["expires_in"]
      assert json_response(conn, 200)["refresh_token"]
    end
  end
end
