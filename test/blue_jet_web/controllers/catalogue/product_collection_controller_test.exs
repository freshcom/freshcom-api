defmodule BlueJetWeb.ProductCollectionControllerTest do
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

  # List product collection
  describe "GET /v1/product_collections" do
    test "without access token", %{conn: conn} do
      conn = get(conn, "/v1/product_collections")

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      account1 = account_fixture()
      account2 = account_fixture()

      product_collection_fixture(account1)
      product_collection_fixture(account1)
      product_collection_fixture(account1, %{status: "draft"})
      product_collection_fixture(account2)

      pat = get_pat(account1)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = get(conn, "/v1/product_collections")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2
    end

    test "with UAT", %{conn: conn} do
      user1 = standard_user_fixture()
      user2 = standard_user_fixture()

      product_collection_fixture(user1.default_account)
      product_collection_fixture(user1.default_account)
      product_collection_fixture(user1.default_account, %{status: "draft"})
      product_collection_fixture(user2.default_account)

      uat = get_uat(user1.default_account, user1)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/product_collections")

      response = json_response(conn, 200)
      assert length(response["data"]) == 3
    end
  end

  # Create a product collection
  describe "POST /v1/product_collections" do
    test "without access token", %{conn: conn} do
      conn = post(conn, "/v1/product_collections", %{
        "data" => %{
          "type" => "ProductCollection"
        }
      })

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      account = account_fixture()
      pat = get_pat(account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = post(conn, "/v1/product_collections", %{
        "data" => %{
          "type" => "ProductCollection"
        }
      })

      assert conn.status == 403
    end

    test "with no attributes", %{conn: conn} do
      user = standard_user_fixture()
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/product_collections", %{
        "data" => %{
          "type" => "ProductCollection"
        }
      })

      response = json_response(conn, 422)
      assert length(response["errors"]) == 1
    end

    test "with valid attributes", %{conn: conn} do
      user = standard_user_fixture()
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/product_collections", %{
        "data" => %{
          "type" => "ProductCollection",
          "attributes" => %{
            "name" => Faker.Commerce.product_name()
          }
        }
      })

      assert json_response(conn, 201)
    end
  end

  # Retrieve a product collection
  describe "GET /v1/product_collections/:id" do
    test "without access token", %{conn: conn} do
      conn = get(conn, "/v1/product_collections/#{UUID.generate()}")

      assert conn.status == 401
    end

    test "with PAT requesting inactive product collection", %{conn: conn} do
      account = account_fixture()
      collection = product_collection_fixture(account, %{status: "draft"})
      pat = get_pat(account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = get(conn, "/v1/product_collections/#{collection.id}")

      assert conn.status == 404
    end

    test "with PAT requesting active product collection", %{conn: conn} do
      account = account_fixture()
      collection = product_collection_fixture(account)
      pat = get_pat(account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = get(conn, "/v1/product_collections/#{collection.id}")

      assert json_response(conn, 200)
    end

    test "with UAT requesting inactive product", %{conn: conn} do
      user = standard_user_fixture()
      collection = product_collection_fixture(user.default_account, %{status: "draft"})
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/product_collections/#{collection.id}")

      assert json_response(conn, 200)
    end
  end

  # Update a product collection
  describe "PATCH /v1/product_collections/:id" do
    test "without access token", %{conn: conn} do
      conn = patch(conn, "/v1/product_collections/#{UUID.generate()}", %{
        "data" => %{
          "type" => "ProductCollection",
          "attributes" => %{
            "name" => Faker.Commerce.product_name()
          }
        }
      })

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      account = account_fixture()
      collection = product_collection_fixture(account)
      pat = get_pat(account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = patch(conn, "/v1/product_collections/#{collection.id}", %{
        "data" => %{
          "id" => collection.id,
          "type" => "ProductCollection",
          "attributes" => %{
            "name" => Faker.Commerce.product_name()
          }
        }
      })

      assert conn.status == 403
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      collection = product_collection_fixture(user.default_account)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/product_collections/#{collection.id}", %{
        "data" => %{
          "id" => collection.id,
          "type" => "ProductCollection",
          "attributes" => %{
            "name" => Faker.Commerce.product_name()
          }
        }
      })

      assert json_response(conn, 200)
    end
  end

  # Delete a product collection
  describe "DELETE /v1/product_collections/:id" do
    test "without access token", %{conn: conn} do
      conn = delete(conn, "/v1/products/#{UUID.generate()}")

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      account = account_fixture()
      collection = product_collection_fixture(account)
      pat = get_pat(account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = delete(conn, "/v1/product_collections/#{collection.id}")

      assert conn.status == 403
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      collection = product_collection_fixture(user.default_account)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = delete(conn, "/v1/product_collections/#{collection.id}")

      assert conn.status == 204
    end
  end
end
