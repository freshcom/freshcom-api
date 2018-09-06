defmodule BlueJetWeb.ProductControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper
  import BlueJet.Goods.TestHelper

  alias BlueJet.Catalogue

  def create_product(user, fields \\ %{}) do
    stockable = create_stockable(user)

    {:ok, %{data: product}} = Catalogue.create_product(%ContextRequest{
      fields: %{
        "name" => Faker.Commerce.product_name(),
        "goods_id" => stockable.id,
        "goods_type" => "Stockable"
      },
      vas: %{ account_id: user.default_account_id, user_id: user.id }
    })

    {:ok, _} = Catalogue.create_price(%ContextRequest{
      params: %{
        "product_id" => product.id
      },
      fields: %{
        "name" => "Regular",
        "status" => "active",
        "charge_amount_cents" => 1000,
        "charge_unit" => "EA"
      },
      vas: %{ account_id: user.default_account_id, user_id: user.id }
    })

    {:ok, %{data: product}} = Catalogue.update_product(%ContextRequest{
      params: %{
        "id" => product.id
      },
      fields: %{
        "status" => fields[:status] || "active"
      },
      vas: %{ account_id: user.default_account_id, user_id: user.id }
    })

    product
  end

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{ conn: conn }
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
      standard_user = create_standard_user()
      pat = get_pat(standard_user)
      conn = put_req_header(conn, "authorization", "Bearer #{pat}")

      conn = post(conn, "/v1/products", %{
        "data" => %{
          "type" => "Product"
        }
      })

      assert conn.status == 403
    end

    test "with no attributes", %{conn: conn} do
      standard_user = create_standard_user()
      uat = get_uat(standard_user)
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
      standard_user = create_standard_user()
      stockable = create_stockable(standard_user)

      uat = get_uat(standard_user)
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
      conn = get(conn, "/v1/products/#{Ecto.UUID.generate()}")

      assert conn.status == 401
    end

    test "with PAT requesting inactive product", %{conn: conn} do
      standard_user = create_standard_user()
      product = create_product(standard_user, %{status: "draft"})

      pat = get_pat(standard_user)
      conn = put_req_header(conn, "authorization", "Bearer #{pat}")

      conn = get(conn, "/v1/products/#{product.id}")

      assert conn.status == 404
    end

    test "with PAT requesting active product of different account", %{conn: conn} do
      standard_user1 = create_standard_user()
      standard_user2 = create_standard_user(n: 2)

      product = create_product(standard_user2)

      pat = get_pat(standard_user1)
      conn = put_req_header(conn, "authorization", "Bearer #{pat}")

      conn = get(conn, "/v1/products/#{product.id}")

      assert conn.status == 404
    end

    test "with PAT requesting active product", %{conn: conn} do
      standard_user = create_standard_user()
      product = create_product(standard_user)

      pat = get_pat(standard_user)
      conn = put_req_header(conn, "authorization", "Bearer #{pat}")

      conn = get(conn, "/v1/products/#{product.id}")

      assert json_response(conn, 200)
    end

    test "with UAT requesting inactive product", %{conn: conn} do
      standard_user = create_standard_user()
      product = create_product(standard_user, %{status: "draft"})

      uat = get_uat(standard_user)
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = get(conn, "/v1/products/#{product.id}")

      assert json_response(conn, 200)
    end

    test "with UAT requesting product of different account", %{conn: conn} do
      standard_user1 = create_standard_user()
      standard_user2 = create_standard_user(n: 2)

      product = create_product(standard_user2)

      uat = get_uat(standard_user1)
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = get(conn, "/v1/products/#{product.id}")

      assert conn.status == 404
    end
  end

  # Update a product
  describe "PATCH /v1/products/:id" do
    test "without access token", %{conn: conn} do
      conn = patch(conn, "/v1/products/#{Ecto.UUID.generate()}", %{
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
      standard_user = create_standard_user()
      product = create_product(standard_user)

      pat = get_pat(standard_user)
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
      standard_user1 = create_standard_user()
      standard_user2 = create_standard_user(n: 2)

      product = create_product(standard_user2)

      uat = get_uat(standard_user1)
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
      standard_user = create_standard_user()
      product = create_product(standard_user)

      uat = get_uat(standard_user)
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
      standard_user = create_standard_user()
      product = create_product(standard_user)

      pat = get_pat(standard_user)
      conn = put_req_header(conn, "authorization", "Bearer #{pat}")

      conn = delete(conn, "/v1/products/#{product.id}")

      assert conn.status == 403
    end

    test "with UAT requesting product of a different account", %{conn: conn} do
      standard_user1 = create_standard_user()
      standard_user2 = create_standard_user(n: 2)

      product = create_product(standard_user2)

      uat = get_uat(standard_user1)
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = delete(conn, "/v1/products/#{product.id}")

      assert conn.status == 404
    end

    test "with UAT", %{conn: conn} do
      standard_user = create_standard_user()
      product = create_product(standard_user)

      uat = get_uat(standard_user)
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = delete(conn, "/v1/products/#{product.id}")

      assert conn.status == 204
    end
  end

  # List product
  describe "GET /v1/products" do
    test "without access token", %{conn: conn} do
      conn = get(conn, "/v1/products")

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      standard_user1 = create_standard_user()
      standard_user2 = create_standard_user(n: 2)

      create_product(standard_user1)
      create_product(standard_user1)
      create_product(standard_user1, %{status: "draft"})
      create_product(standard_user2)

      pat = get_pat(standard_user1)
      conn = put_req_header(conn, "authorization", "Bearer #{pat}")

      conn = get(conn, "/v1/products")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2
    end

    test "with UAT", %{conn: conn} do
      standard_user1 = create_standard_user()
      standard_user2 = create_standard_user(n: 2)

      create_product(standard_user1)
      create_product(standard_user1)
      create_product(standard_user1, %{status: "draft"})
      create_product(standard_user2)

      uat = get_uat(standard_user1)
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = get(conn, "/v1/products")

      response = json_response(conn, 200)
      assert length(response["data"]) == 3
    end
  end
end
