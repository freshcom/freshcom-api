defmodule BlueJetWeb.PointTransactionControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper
  import BlueJet.CRM.TestHelper

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{conn: conn}
  end

  # List point transaction
  describe "GET /v1/point_accounts/:id/transactions" do
    test "without access token", %{conn: conn} do
      conn = get(conn, "/v1/point_accounts/#{UUID.generate()}/transactions")

      assert conn.status == 401
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      point_account1 = customer_fixture(user.default_account).point_account
      point_account2 = customer_fixture(user.default_account).point_account

      point_transaction_fixture(user.default_account, point_account1, %{status: "committed"})
      point_transaction_fixture(user.default_account, point_account1, %{status: "committed"})
      point_transaction_fixture(user.default_account, point_account1)
      point_transaction_fixture(user.default_account, point_account2, %{status: "committed"})

      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/point_accounts/#{point_account1.id}/transactions")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2
    end
  end

  # Create a point transaction
  describe "POST /v1/point_transactions" do
    test "without access token", %{conn: conn} do
      conn = post(conn, "/v1/point_accounts/#{UUID.generate()}/transactions", %{
        "data" => %{
          "type" => "PointTransaction"
        }
      })

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      user = standard_user_fixture()
      customer = customer_fixture(user.default_account)
      point_account = customer.point_account
      pat = get_pat(user.default_account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = post(conn, "/v1/point_accounts/#{point_account.id}/transactions", %{
        "data" => %{
          "type" => "PointTransaction"
        }
      })

      assert conn.status == 403
    end

    test "with UAT and invalid fields", %{conn: conn} do
      account = account_fixture()
      customer = customer_fixture(account, %{status: "registered"})
      point_account = customer.point_account
      user = customer.user
      uat = get_uat(account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/point_accounts/#{point_account.id}/transactions", %{
        "data" => %{
          "type" => "PointTransaction"
        }
      })

      response = json_response(conn, 422)
      assert length(response["errors"]) == 1
    end
  end

  # Retrieve a point transaction
  describe "GET /v1/point_transactions/:id" do
    test "without access token", %{conn: conn} do
      conn = get(conn, "/v1/point_transactions/#{UUID.generate()}")

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      user = standard_user_fixture()
      pat = get_pat(user.default_account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = get(conn, "/v1/point_transactions/#{UUID.generate()}")

      assert conn.status == 403
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      customer = customer_fixture(user.default_account)
      point_account = customer.point_account
      point_transaction = point_transaction_fixture(user.default_account, point_account)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/point_transactions/#{point_transaction.id}")

      assert json_response(conn, 200)
    end
  end

  # Update a point transaction
  describe "PATCH /v1/point_transactions/:id" do
    test "without access token", %{conn: conn} do
      conn = patch(conn, "/v1/point_transactions/#{UUID.generate()}", %{
        "data" => %{
          "type" => "PointTransaction",
          "attributes" => %{
            "name" => Faker.Name.name()
          }
        }
      })

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      user = standard_user_fixture()
      pat = get_pat(user.default_account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = patch(conn, "/v1/point_transactions/#{UUID.generate()}", %{
        "data" => %{
          "type" => "PointTransaction",
          "attributes" => %{
            "name" => Faker.Name.name()
          }
        }
      })

      assert conn.status == 403
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      customer = customer_fixture(user.default_account)
      point_account = customer.point_account
      point_transaction = point_transaction_fixture(user.default_account, point_account)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/point_transactions/#{point_transaction.id}", %{
        "data" => %{
          "type" => "PointTransaction",
          "attributes" => %{
            "status" => "committed"
          }
        }
      })

      assert json_response(conn, 200)
    end
  end

  # Delete a point transaction
  describe "DELETE /v1/point_transactions/:id" do
    test "without access token", %{conn: conn} do
      conn = delete(conn, "/v1/point_transactions/#{UUID.generate()}")

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      user = standard_user_fixture()
      customer = customer_fixture(user.default_account)
      point_account = customer.point_account
      point_transaction = point_transaction_fixture(user.default_account, point_account)
      pat = get_pat(user.default_account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = delete(conn, "/v1/point_transactions/#{point_transaction.id}")

      assert conn.status == 403
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      customer = customer_fixture(user.default_account)
      point_account = customer.point_account
      point_transaction = point_transaction_fixture(user.default_account, point_account)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = delete(conn, "/v1/point_transactions/#{point_transaction.id}")

      assert conn.status == 204
    end
  end
end
