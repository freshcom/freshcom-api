defmodule BlueJetWeb.ProductControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper
  import BlueJet.Goods.TestHelper
  import BlueJet.Catalogue.TestHelper

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{ conn: conn }
  end

  # List product
  describe "GET /v1/products" do
    test "without access token", %{conn: conn} do
      conn = get(conn, "/v1/products")

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      account1 = account_fixture()
      account2 = account_fixture()

      product_fixture(account1, %{status: "active"})
      product_fixture(account1, %{status: "active"})
      product_fixture(account1)
      product_fixture(account2, %{status: "active"})

      pat = get_pat(account1)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = get(conn, "/v1/products")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2
    end

    test "with UAT", %{conn: conn} do
      user1 = standard_user_fixture()
      user2 = standard_user_fixture()

      product_fixture(user1.default_account, %{status: "active"})
      product_fixture(user1.default_account, %{status: "active"})
      product_fixture(user1.default_account)
      product_fixture(user2.default_account)

      uat = get_uat(user1.default_account, user1)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/products")

      response = json_response(conn, 200)
      assert length(response["data"]) == 3
    end
  end

  # Create a product
  describe "POST /v1/products" do
    test "without access token", %{conn: conn} do
      conn = post(conn, "/v1/products", %{
        "data" => %{
          "type" => "Product"
        }
      })

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      account = account_fixture()
      pat = get_pat(account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = post(conn, "/v1/products", %{
        "data" => %{
          "type" => "Product"
        }
      })

      assert conn.status == 403
    end

    test "with no attributes", %{conn: conn} do
      user = standard_user_fixture()
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/products", %{
        "data" => %{
          "type" => "Product"
        }
      })

      response = json_response(conn, 422)
      assert length(response["errors"]) == 3
    end

    test "with valid attributes", %{conn: conn} do
      user = standard_user_fixture()
      stockable = stockable_fixture(user.default_account)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/products", %{
        "data" => %{
          "type" => "Product",
          "attributes" => %{
            "name" => Faker.Commerce.product_name()
          },
          "relationships" => %{
            "goods" => %{
              "data" => %{
                "id" => stockable.id,
                "type" => "Stockable"
              }
            }
          }
        }
      })

      assert json_response(conn, 201)
    end
  end

  # Retrieve a product
  describe "GET /v1/products/:id" do
    test "without access token", %{conn: conn} do
      conn = get(conn, "/v1/products/#{UUID.generate()}")

      assert conn.status == 401
    end

    test "with PAT requesting inactive product", %{conn: conn} do
      account = account_fixture()
      product = product_fixture(account)
      pat = get_pat(account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = get(conn, "/v1/products/#{product.id}")

      assert conn.status == 404
    end

    test "with PAT requesting active product of different account", %{conn: conn} do
      account1 = account_fixture()
      account2 = account_fixture()
      product = product_fixture(account2, %{status: "active"})
      pat = get_pat(account1)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = get(conn, "/v1/products/#{product.id}")

      assert conn.status == 404
    end

    test "with PAT requesting active product", %{conn: conn} do
      account = account_fixture()
      product = product_fixture(account, %{status: "active"})
      pat = get_pat(account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = get(conn, "/v1/products/#{product.id}")

      assert json_response(conn, 200)
    end

    test "with UAT requesting inactive product", %{conn: conn} do
      user = standard_user_fixture()
      product = product_fixture(user.default_account)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/products/#{product.id}")

      assert json_response(conn, 200)
    end

    test "with UAT requesting product of different account", %{conn: conn} do
      user1 = standard_user_fixture()
      user2 = standard_user_fixture()
      product = product_fixture(user2.default_account)
      uat = get_uat(user1.default_account, user1)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/products/#{product.id}")

      assert conn.status == 404
    end
  end

  # Update a product
  describe "PATCH /v1/products/:id" do
    test "without access token", %{conn: conn} do
      conn = patch(conn, "/v1/products/#{UUID.generate()}", %{
        "data" => %{
          "type" => "Product",
          "attributes" => %{
            "name" => Faker.Commerce.product_name()
          }
        }
      })

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      user = standard_user_fixture()
      product = product_fixture(user.default_account, %{status: "active"})
      pat = get_pat(user.default_account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = patch(conn, "/v1/products/#{product.id}", %{
        "data" => %{
          "id" => product.id,
          "type" => "Product",
          "attributes" => %{
            "name" => Faker.Commerce.product_name()
          }
        }
      })

      assert conn.status == 403
    end

    test "with UAT requesting product of a different account", %{conn: conn} do
      user1 = standard_user_fixture()
      user2 = standard_user_fixture()
      product = product_fixture(user2.default_account, %{status: "active"})
      uat = get_uat(user1.default_account, user1)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/products/#{product.id}", %{
        "data" => %{
          "id" => product.id,
          "type" => "Product",
          "attributes" => %{
            "name" => Faker.Commerce.product_name()
          }
        }
      })

      assert conn.status == 404
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      product = product_fixture(user.default_account)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/products/#{product.id}", %{
        "data" => %{
          "id" => product.id,
          "type" => "Product",
          "attributes" => %{
            "name" => Faker.Commerce.product_name()
          }
        }
      })

      assert json_response(conn, 200)
    end
  end

  # Delete a product
  describe "DELETE /v1/products/:id" do
    test "without access token", %{conn: conn} do
      conn = delete(conn, "/v1/products/#{Ecto.UUID.generate()}")

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      account = account_fixture()
      product = product_fixture(account, %{status: "active"})
      pat = get_pat(account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = delete(conn, "/v1/products/#{product.id}")

      assert conn.status == 403
    end

    test "with UAT requesting product of a different account", %{conn: conn} do
      user1 = standard_user_fixture()
      user2 = standard_user_fixture()
      product = product_fixture(user2.default_account, %{status: "active"})
      uat = get_uat(user1.default_account, user1)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = delete(conn, "/v1/products/#{product.id}")

      assert conn.status == 404
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      product = product_fixture(user.default_account)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = delete(conn, "/v1/products/#{product.id}")

      assert conn.status == 204
    end
  end
end
