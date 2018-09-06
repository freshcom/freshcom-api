defmodule BlueJetWeb.PriceControllerTest do
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
        "charge_unit" => "EA",
        "minimum_order_quantity" => 99
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

  def create_price(user, fields \\ %{}) do
    product_id = fields[:product_id] || create_product(user).id

    {:ok, %{data: price}} = Catalogue.create_price(%ContextRequest{
      params: %{
        "product_id" => product_id
      },
      fields: %{
        "name" => "Regular",
        "status" => fields[:status] || "active",
        "charge_amount_cents" => 1000,
        "charge_unit" => "EA"
      },
      vas: %{ account_id: user.default_account_id, user_id: user.id }
    })

    price
  end

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{ conn: conn }
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
      standard_user = create_standard_user()
      product = create_product(standard_user)

      pat = get_pat(standard_user)
      conn = put_req_header(conn, "authorization", "Bearer #{pat}")

      conn = post(conn, "/v1/products/#{product.id}/prices", %{
        "data" => %{
          "type" => "Price"
        }
      })

      assert conn.status == 403
    end

    test "with no attributes", %{conn: conn} do
      standard_user = create_standard_user()
      product = create_product(standard_user)

      uat = get_uat(standard_user)
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
      standard_user = create_standard_user()
      product = create_product(standard_user)

      uat = get_uat(standard_user)
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
      standard_user = create_standard_user()
      price = create_price(standard_user, %{status: "draft"})

      pat = get_pat(standard_user)
      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = get(conn, "/v1/prices/#{price.id}")

      assert conn.status == 404
    end

    test "with PAT requesting active price", %{conn: conn} do
      standard_user = create_standard_user()
      price = create_price(standard_user)

      pat = get_pat(standard_user)
      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = get(conn, "/v1/prices/#{price.id}")

      assert json_response(conn, 200)
    end

    test "with PAT requesting price of a different account", %{conn: conn} do
      standard_user1 = create_standard_user()
      standard_user2 = create_standard_user(n: 2)

      price = create_price(standard_user2)

      pat = get_pat(standard_user1)
      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = get(conn, "/v1/prices/#{price.id}")

      assert conn.status == 404
    end

    test "with UAT requesting inactive price", %{conn: conn} do
      standard_user = create_standard_user()
      price = create_price(standard_user, %{status: "draft"})

      uat = get_uat(standard_user)
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/prices/#{price.id}")

      assert conn.status == 200
    end

    test "with UAT requesting price of a different account", %{conn: conn} do
      standard_user1 = create_standard_user()
      standard_user2 = create_standard_user(n: 2)

      price = create_price(standard_user2)

      uat = get_uat(standard_user1)
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
      standard_user = create_standard_user()
      price = create_price(standard_user)

      pat = get_pat(standard_user)
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
      standard_user1 = create_standard_user()
      standard_user2 = create_standard_user(n: 2)

      price = create_price(standard_user2)

      uat = get_uat(standard_user1)
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
      standard_user = create_standard_user()
      price = create_price(standard_user)

      uat = get_uat(standard_user)
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      new_name = "Employee"
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
      standard_user = create_standard_user()
      price = create_price(standard_user)

      pat = get_pat(standard_user)
      conn = put_req_header(conn, "authorization", "Bearer #{pat}")

      conn = delete(conn, "/v1/prices/#{price.id}")

      assert conn.status == 403
    end

    test "with UAT requesting price of a different account", %{conn: conn} do
      standard_user1 = create_standard_user()
      standard_user2 = create_standard_user(n: 2)

      price = create_price(standard_user2)

      uat = get_uat(standard_user1)
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = delete(conn, "/v1/prices/#{price.id}")

      assert conn.status == 404
    end

    test "with UAT", %{conn: conn} do
      standard_user = create_standard_user()
      price = create_price(standard_user)

      uat = get_uat(standard_user)
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = delete(conn, "/v1/prices/#{price.id}")

      assert conn.status == 204
    end
  end

  # List price
  describe "GET /v1/products/:id/prices" do
    test "without access token", %{conn: conn} do
      conn = get(conn, "/v1/products/#{Ecto.UUID.generate()}/prices")

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      standard_user1 = create_standard_user()
      standard_user2 = create_standard_user(n: 2)

      product = create_product(standard_user1)

      create_price(standard_user1, %{product_id: product.id})
      create_price(standard_user1, %{product_id: product.id, status: "draft"})
      create_price(standard_user2)

      pat = get_pat(standard_user1)
      conn = put_req_header(conn, "authorization", "Bearer #{pat}")

      conn = get(conn, "/v1/products/#{product.id}/prices")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2
    end

    test "with UAT", %{conn: conn} do
      standard_user1 = create_standard_user()
      standard_user2 = create_standard_user(n: 2)

      product = create_product(standard_user1)

      create_price(standard_user1, %{product_id: product.id})
      create_price(standard_user1, %{product_id: product.id, status: "draft"})
      create_price(standard_user2)

      uat = get_uat(standard_user1)
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = get(conn, "/v1/products/#{product.id}/prices")

      response = json_response(conn, 200)
      assert length(response["data"]) == 3
    end
  end
end
