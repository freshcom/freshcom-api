defmodule BlueJetWeb.PointTransactionControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper
  import BlueJet.Crm.TestHelper

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

  # # Create a point_transaction
  # describe "POST /v1/point_transactions" do
  #   test "without access token", %{conn: conn} do
  #     conn = post(conn, "/v1/point_transactions", %{
  #       "data" => %{
  #         "type" => "PointTransaction"
  #       }
  #     })

  #     assert conn.status == 401
  #   end

  #   test "with PAT and invalid fields", %{conn: conn} do
  #     user = standard_user_fixture()
  #     pat = get_pat(user.default_account)

  #     conn = put_req_header(conn, "authorization", "Bearer #{pat}")
  #     conn = post(conn, "/v1/point_transactions", %{
  #       "data" => %{
  #         "type" => "PointTransaction"
  #       }
  #     })

  #     response = json_response(conn, 422)
  #     assert length(response["errors"]) == 3
  #   end

  #   test "with PAT and valid fields", %{conn: conn} do
  #     user = standard_user_fixture()
  #     pat = get_pat(user.default_account)

  #     conn = put_req_header(conn, "authorization", "Bearer #{pat}")
  #     conn = post(conn, "/v1/point_transactions", %{
  #       "data" => %{
  #         "type" => "PointTransaction",
  #         "attributes" => %{
  #           "status" => "guest"
  #         }
  #       }
  #     })

  #     assert json_response(conn, 201)
  #   end
  # end

  # # Retrieve current point_transaction
  # describe "GET /v1/point_transaction" do
  #   test "without access token", %{conn: conn} do
  #     conn = get(conn, "/v1/point_transaction")

  #     assert conn.status == 401
  #   end

  #   test "with UAT", %{conn: conn} do
  #     account = account_fixture()
  #     point_transaction = point_transaction_fixture(account, %{status: "registered"})
  #     user = point_transaction.user
  #     uat = get_uat(account, user)

  #     conn = put_req_header(conn, "authorization", "Bearer #{uat}")
  #     conn = get(conn, "/v1/point_transaction")

  #     response = json_response(conn, 200)
  #     assert response["data"]["id"] == point_transaction.id
  #   end
  # end

  # # Retrieve a point_transaction
  # describe "GET /v1/point_transactions/:id" do
  #   test "without access token", %{conn: conn} do
  #     conn = get(conn, "/v1/point_transactions/#{UUID.generate()}")

  #     assert conn.status == 401
  #   end

  #   test "with PAT", %{conn: conn} do
  #     user = standard_user_fixture()
  #     pat = get_pat(user.default_account)

  #     conn = put_req_header(conn, "authorization", "Bearer #{pat}")
  #     conn = get(conn, "/v1/point_transactions/#{UUID.generate()}")

  #     assert conn.status == 403
  #   end

  #   test "with UAT", %{conn: conn} do
  #     user = standard_user_fixture()
  #     point_transaction = point_transaction_fixture(user.default_account)
  #     uat = get_uat(user.default_account, user)

  #     conn = put_req_header(conn, "authorization", "Bearer #{uat}")
  #     conn = get(conn, "/v1/point_transactions/#{point_transaction.id}")

  #     assert json_response(conn, 200)
  #   end
  # end

  # # Update a point_transaction
  # describe "PATCH /v1/point_transactions/:id" do
  #   test "without access token", %{conn: conn} do
  #     conn = patch(conn, "/v1/point_transactions/#{UUID.generate()}", %{
  #       "data" => %{
  #         "type" => "PointTransaction",
  #         "attributes" => %{
  #           "name" => Faker.Name.name()
  #         }
  #       }
  #     })

  #     assert conn.status == 401
  #   end

  #   test "with PAT", %{conn: conn} do
  #     user = standard_user_fixture()
  #     pat = get_pat(user.default_account)

  #     conn = put_req_header(conn, "authorization", "Bearer #{pat}")
  #     conn = patch(conn, "/v1/point_transactions/#{UUID.generate()}", %{
  #       "data" => %{
  #         "type" => "PointTransaction",
  #         "attributes" => %{
  #           "name" => Faker.Name.name()
  #         }
  #       }
  #     })

  #     assert conn.status == 403
  #   end

  #   test "with UAT", %{conn: conn} do
  #     user = standard_user_fixture()
  #     point_transaction = point_transaction_fixture(user.default_account)
  #     uat = get_uat(user.default_account, user)

  #     conn = put_req_header(conn, "authorization", "Bearer #{uat}")
  #     conn = patch(conn, "/v1/point_transactions/#{point_transaction.id}", %{
  #       "data" => %{
  #         "type" => "PointTransaction",
  #         "attributes" => %{
  #           "name" => Faker.Name.name()
  #         }
  #       }
  #     })

  #     assert json_response(conn, 200)
  #   end
  # end

  # # Delete a point_transaction
  # describe "DELETE /v1/point_transactions/:id" do
  #   test "without access token", %{conn: conn} do
  #     conn = delete(conn, "/v1/point_transactions/#{UUID.generate()}")

  #     assert conn.status == 401
  #   end

  #   test "with PAT", %{conn: conn} do
  #     user = standard_user_fixture()
  #     pat = get_pat(user.default_account)

  #     conn = put_req_header(conn, "authorization", "Bearer #{pat}")
  #     conn = delete(conn, "/v1/point_transactions/#{UUID.generate()}")

  #     assert conn.status == 403
  #   end

  #   test "with UAT", %{conn: conn} do
  #     user = standard_user_fixture()
  #     point_transaction = point_transaction_fixture(user.default_account)
  #     uat = get_uat(user.default_account, user)

  #     conn = put_req_header(conn, "authorization", "Bearer #{uat}")
  #     conn = delete(conn, "/v1/point_transactions/#{point_transaction.id}")

  #     assert conn.status == 204
  #   end
  # end
end
