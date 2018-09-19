defmodule BlueJetWeb.PriceControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper
  import BlueJet.Catalogue.TestHelper

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{conn: conn}
  end

  # List price
  describe "GET /v1/products/:id/prices" do
    test "without access token", %{conn: conn} do
      conn = get(conn, "/v1/products/#{Ecto.UUID.generate()}/prices")

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      account1 = account_fixture()
      account2 = account_fixture()

      product1 = product_fixture(account1)
      product2 = product_fixture(account2)

      price_fixture(account1, product1)
      price_fixture(account1, product1, %{status: "draft"})
      price_fixture(account1, product1)
      price_fixture(account2, product2)

      pat = get_pat(account1)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = get(conn, "/v1/products/#{product1.id}/prices")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2
    end

    test "with UAT", %{conn: conn} do
      user1 = standard_user_fixture()
      user2 = standard_user_fixture()
      product1 = product_fixture(user1.default_account)
      product2 = product_fixture(user2.default_account)

      price_fixture(user1.default_account, product1)
      price_fixture(user1.default_account, product1, %{status: "draft"})
      price_fixture(user2.default_account, product2)

      uat = get_uat(user1.default_account, user1)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/products/#{product1.id}/prices")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2
    end
  end

  # Create a price
  describe "POST /v1/products/:id/prices" do
    test "without access token", %{conn: conn} do
      conn = post(conn, "/v1/products/#{Ecto.UUID.generate()}/prices", %{
        "data" => %{
          "type" => "Price"
        }
      })

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      account = account_fixture()
      product = product_fixture(account)
      pat = get_pat(account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = post(conn, "/v1/products/#{product.id}/prices", %{
        "data" => %{
          "type" => "Price"
        }
      })

      assert conn.status == 403
    end

    test "with no attributes", %{conn: conn} do
      user = standard_user_fixture()
      product = product_fixture(user.default_account)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/products/#{product.id}/prices", %{
        "data" => %{
          "type" => "Price"
        }
      })

      response = json_response(conn, 422)
      assert length(response["errors"]) == 3
    end

    test "with valid attributes", %{conn: conn} do
      user = standard_user_fixture()
      product = product_fixture(user.default_account)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/products/#{product.id}/prices", %{
        "data" => %{
          "type" => "Price",
          "attributes" => %{
            "name" => "Regular",
            "charge_amount_cents" => 5000,
            "charge_unit" => "EA"
          }
        }
      })

      assert json_response(conn, 201)
    end
  end

  # Retrieve a price
  describe "GET /v1/prices/:id" do
    test "without access token", %{conn: conn} do
      conn = get(conn, "/v1/prices/#{Ecto.UUID.generate()}")

      assert conn.status == 401
    end

    test "with PAT requesting inactive price", %{conn: conn} do
      account = account_fixture()
      product = product_fixture(account)
      price = price_fixture(account, product, %{status: "draft"})
      pat = get_pat(account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = get(conn, "/v1/prices/#{price.id}")

      assert conn.status == 404
    end

    test "with PAT requesting active price", %{conn: conn} do
      account = account_fixture()
      product = product_fixture(account)
      price = price_fixture(account, product)
      pat = get_pat(account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = get(conn, "/v1/prices/#{price.id}")

      assert json_response(conn, 200)
    end

    test "with PAT requesting price of a different account", %{conn: conn} do
      account1 = account_fixture()
      account2 = account_fixture()
      product = product_fixture(account2)
      price = price_fixture(account2, product)
      pat = get_pat(account1)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = get(conn, "/v1/prices/#{price.id}")

      assert conn.status == 404
    end

    test "with UAT requesting inactive price", %{conn: conn} do
      user = standard_user_fixture()
      product = product_fixture(user.default_account)
      price = price_fixture(user.default_account, product, %{status: "draft"})
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/prices/#{price.id}")

      assert conn.status == 200
    end

    test "with UAT requesting price of a different account", %{conn: conn} do
      user1 = standard_user_fixture()
      user2 = standard_user_fixture()
      product = product_fixture(user2.default_account)
      price = price_fixture(user2.default_account, product)
      uat = get_uat(user1.default_account, user1)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/prices/#{price.id}")

      assert conn.status == 404
    end
  end

  # Update a price
  describe "PATCH /v1/prices/:id" do
    test "without access token", %{conn: conn} do
      conn = patch(conn, "/v1/prices/#{Ecto.UUID.generate()}", %{
        "data" => %{
          "type" => "Price",
          "attributes" => %{
            "name" => "Employee Price"
          }
        }
      })

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      account = account_fixture()
      product = product_fixture(account)
      price = price_fixture(account, product)
      pat = get_pat(account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = patch(conn, "/v1/prices/#{price.id}", %{
        "data" => %{
          "id" => price.id,
          "type" => "Price",
          "attributes" => %{
            "name" => "Employee Price"
          }
        }
      })

      assert conn.status == 403
    end

    test "with UAT requesting price of a different account", %{conn: conn} do
      user1 = standard_user_fixture()
      user2 = standard_user_fixture()
      product = product_fixture(user2.default_account)
      price = price_fixture(user2.default_account, product)
      uat = get_uat(user1.default_account, user1)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/prices/#{price.id}", %{
        "data" => %{
          "id" => price.id,
          "type" => "Price",
          "attributes" => %{
            "name" => "Employee Price"
          }
        }
      })

      assert conn.status == 404
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      product = product_fixture(user.default_account)
      price = price_fixture(user.default_account, product)
      uat = get_uat(user.default_account, user)
      new_name = "Employee"

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/prices/#{price.id}", %{
        "data" => %{
          "id" => price.id,
          "type" => "Price",
          "attributes" => %{
            "name" => new_name
          }
        }
      })

      response = json_response(conn, 200)
      assert response["data"]["attributes"]["name"] == new_name
    end
  end

  # Delete a price
  describe "DELETE /v1/prices/:id" do
    test "without access token", %{conn: conn} do
      conn = delete(conn, "/v1/prices/#{Ecto.UUID.generate()}")

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      account = account_fixture()
      product = product_fixture(account)
      price = price_fixture(account, product)
      pat = get_pat(account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = delete(conn, "/v1/prices/#{price.id}")

      assert conn.status == 403
    end

    test "with UAT requesting price of a different account", %{conn: conn} do
      user1 = standard_user_fixture()
      user2 = standard_user_fixture()
      product = product_fixture(user2.default_account)
      price = price_fixture(user2.default_account, product)
      uat = get_uat(user1.default_account, user1)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = delete(conn, "/v1/prices/#{price.id}")

      assert conn.status == 404
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      product = product_fixture(user.default_account)
      price = price_fixture(user.default_account, product)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = delete(conn, "/v1/prices/#{price.id}")

      assert conn.status == 204
    end
  end
end
