defmodule BlueJetWeb.CustomerControllerTest do
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

  # List customer
  describe "GET /v1/customers" do
    test "without access token", %{conn: conn} do
      conn = get(conn, "/v1/customers")

      assert conn.status == 401
    end

    test "with UAT", %{conn: conn} do
      user1 = standard_user_fixture()
      user2 = standard_user_fixture()

      customer_fixture(user1.default_account)
      customer_fixture(user1.default_account)
      customer_fixture(user2.default_account)

      uat = get_uat(user1.default_account, user1)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/customers")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2
    end
  end

  # Create a customer
  describe "POST /v1/customers" do
    test "without access token", %{conn: conn} do
      conn = post(conn, "/v1/customers", %{
        "data" => %{
          "type" => "Customer"
        }
      })

      assert conn.status == 401
    end

    test "with PAT and invalid fields", %{conn: conn} do
      user = standard_user_fixture()
      pat = get_pat(user.default_account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = post(conn, "/v1/customers", %{
        "data" => %{
          "type" => "Customer"
        }
      })

      response = json_response(conn, 422)
      assert length(response["errors"]) == 3
    end

    test "with PAT and valid fields", %{conn: conn} do
      user = standard_user_fixture()
      pat = get_pat(user.default_account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = post(conn, "/v1/customers", %{
        "data" => %{
          "type" => "Customer",
          "attributes" => %{
            "status" => "guest"
          }
        }
      })

      assert json_response(conn, 201)
    end
  end

  # Retrieve current customer
  describe "GET /v1/customer" do
    test "without access token", %{conn: conn} do
      conn = get(conn, "/v1/customer")

      assert conn.status == 401
    end

    test "with UAT", %{conn: conn} do
      account = account_fixture()
      customer = customer_fixture(account, %{status: "registered"})
      user = customer.user
      uat = get_uat(account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/customer")

      response = json_response(conn, 200)
      assert response["data"]["id"] == customer.id
    end
  end

  # Retrieve a customer
  describe "GET /v1/customers/:id" do
    test "without access token", %{conn: conn} do
      conn = get(conn, "/v1/customers/#{UUID.generate()}")

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      user = standard_user_fixture()
      pat = get_pat(user.default_account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = get(conn, "/v1/customers/#{UUID.generate()}")

      assert conn.status == 403
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      customer = customer_fixture(user.default_account)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/customers/#{customer.id}")

      assert json_response(conn, 200)
    end
  end

  # Update a customer
  describe "PATCH /v1/customers/:id" do
    test "without access token", %{conn: conn} do
      conn = patch(conn, "/v1/customers/#{UUID.generate()}", %{
        "data" => %{
          "type" => "Customer",
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
      conn = patch(conn, "/v1/customers/#{UUID.generate()}", %{
        "data" => %{
          "type" => "Customer",
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
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/customers/#{customer.id}", %{
        "data" => %{
          "type" => "Customer",
          "attributes" => %{
            "name" => Faker.Name.name()
          }
        }
      })

      assert json_response(conn, 200)
    end
  end

  # Delete a customer
  describe "DELETE /v1/customers/:id" do
    test "without access token", %{conn: conn} do
      conn = delete(conn, "/v1/customers/#{UUID.generate()}")

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      user = standard_user_fixture()
      pat = get_pat(user.default_account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = delete(conn, "/v1/customers/#{UUID.generate()}")

      assert conn.status == 403
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      customer = customer_fixture(user.default_account)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = delete(conn, "/v1/customers/#{customer.id}")

      assert conn.status == 204
    end
  end
end
