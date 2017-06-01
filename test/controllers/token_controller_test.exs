defmodule BlueJet.RefreshTokenControllerTest do
  use BlueJet.ConnCase

  alias BlueJet.UserRegistration
  alias BlueJet.CustomerRegistration
  alias BlueJet.RefreshToken

  setup do
    conn = build_conn()
      |> put_req_header("content-type", "application/x-www-form-urlencoded")

    {_, %{ default_account_id: account1_id }} = UserRegistration.sign_up(%{
      first_name: Faker.Name.first_name,
      last_name: Faker.Name.last_name,
      email: "user1@example.com",
      password: "test1234",
      account_name: "Outersky"
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
      CustomerRegistration.sign_up(%{
        first_name: Faker.Name.first_name(),
        last_name: Faker.Name.last_name(),
        email: email,
        password: password,
        account_id: account1_id
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
