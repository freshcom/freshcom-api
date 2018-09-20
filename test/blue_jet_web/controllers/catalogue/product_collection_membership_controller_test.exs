defmodule BlueJetWeb.ProductCollectionMembershipControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper
  import BlueJet.Catalogue.TestHelper

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{ conn: conn }
  end

  # List product collection membership
  describe "GET /v1/product_collections/:id/memberships" do
    test "without access token", %{conn: conn} do
      conn = get(conn, "/v1/product_collections/#{UUID.generate()}/memberships")

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      account1 = account_fixture()
      account2 = account_fixture()

      collection1 = product_collection_fixture(account1)
      collection2 = product_collection_fixture(account2)

      product11 = product_fixture(account1)
      product12 = product_fixture(account1, %{status: "active"})
      product21 = product_fixture(account2)

      product_collection_membership_fixture(account1, collection1, product11)
      product_collection_membership_fixture(account1, collection1, product12)
      product_collection_membership_fixture(account2, collection2, product21)

      pat = get_pat(account1)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = get(conn, "/v1/product_collections/#{collection1.id}/memberships")

      response = json_response(conn, 200)
      assert length(response["data"]) == 1
    end

    test "with UAT", %{conn: conn} do
      user1 = standard_user_fixture()
      user2 = standard_user_fixture()
      account1 = user1.default_account
      account2 = user2.default_account

      collection1 = product_collection_fixture(account1)
      collection2 = product_collection_fixture(account2)

      product11 = product_fixture(account1)
      product12 = product_fixture(account1, %{status: "active"})
      product21 = product_fixture(account2)

      product_collection_membership_fixture(account1, collection1, product11)
      product_collection_membership_fixture(account1, collection1, product12)
      product_collection_membership_fixture(account2, collection2, product21)

      uat = get_uat(account1, user1)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/product_collections/#{collection1.id}/memberships")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2
    end
  end

  # Create a product collection
  describe "POST /v1/product_collections/:id/memberships" do
    test "without access token", %{conn: conn} do
      conn = post(conn, "/v1/product_collections/#{UUID.generate()}/memberships", %{
        "data" => %{
          "type" => "ProductCollectionMembership"
        }
      })

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      account = account_fixture()
      pat = get_pat(account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = post(conn, "/v1/product_collections/#{UUID.generate()}/memberships", %{
        "data" => %{
          "type" => "ProductCollectionMembership"
        }
      })

      assert conn.status == 403
    end

    test "with no attributes", %{conn: conn} do
      user = standard_user_fixture()
      collection = product_collection_fixture(user.default_account)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/product_collections/#{collection.id}/memberships", %{
        "data" => %{
          "type" => "ProductCollectionMembership"
        }
      })

      response = json_response(conn, 422)
      assert length(response["errors"]) == 2
    end

    test "with valid attributes", %{conn: conn} do
      user = standard_user_fixture()
      collection = product_collection_fixture(user.default_account)
      product = product_fixture(user.default_account)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/product_collections/#{collection.id}/memberships", %{
        "data" => %{
          "type" => "ProductCollectionMembership",
          "attributes" => %{
            "name" => Faker.Commerce.product_name()
          },
          "relationships" => %{
            "collection" => %{
              "data" => %{
                "id" => collection.id,
                "type" => "ProductCollection"
              }
            },
            "product" => %{
              "data" => %{
                "id" => product.id,
                "type" => "Product"
              }
            }
          }
        }
      })

      assert json_response(conn, 201)
    end
  end

  # Retrieve a product collection membership
  describe "GET /v1/product_collection_memberships/:id" do
    test "without access token", %{conn: conn} do
      conn = get(conn, "/v1/product_collection_memberships/#{UUID.generate()}")

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      account = account_fixture()
      collection = product_collection_fixture(account)
      product = product_fixture(account, %{status: "active"})
      membership = product_collection_membership_fixture(account, collection, product)
      pat = get_pat(account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = get(conn, "/v1/product_collection_memberships/#{membership.id}")

      assert conn.status == 403
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      collection = product_collection_fixture(user.default_account)
      product = product_fixture(user.default_account)
      membership = product_collection_membership_fixture(user.default_account, collection, product)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/product_collection_memberships/#{membership.id}")

      assert json_response(conn, 200)
    end
  end

  # Update a product
  describe "PATCH /v1/product_collection_memberships/:id" do
    test "without access token", %{conn: conn} do
      conn = patch(conn, "/v1/product_collection_memberships/#{UUID.generate()}", %{
        "data" => %{
          "type" => "ProductCollectionMembership",
          "attributes" => %{
            "sortIndex" => System.unique_integer([:positive])
          }
        }
      })

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      account = account_fixture()
      collection = product_collection_fixture(account)
      product = product_fixture(account, %{status: "active"})
      membership = product_collection_membership_fixture(account, collection, product)
      pat = get_pat(account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = patch(conn, "/v1/product_collection_memberships/#{membership.id}", %{
        "data" => %{
          "id" => membership.id,
          "type" => "ProductCollectionMembership",
          "attributes" => %{
            "sortIndex" => System.unique_integer([:positive])
          }
        }
      })

      assert conn.status == 403
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      collection = product_collection_fixture(user.default_account)
      product = product_fixture(user.default_account)
      membership = product_collection_membership_fixture(user.default_account, collection, product)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/product_collection_memberships/#{membership.id}", %{
        "data" => %{
          "id" => membership.id,
          "type" => "ProductCollectionMembership",
          "attributes" => %{
            "sortIndex" => System.unique_integer([:positive])
          }
        }
      })

      assert json_response(conn, 200)
    end
  end

  # Delete a product
  describe "DELETE /v1/product_collection_memberships/:id" do
    test "without access token", %{conn: conn} do
      conn = delete(conn, "/v1/products/#{UUID.generate()}")

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      account = account_fixture()
      collection = product_collection_fixture(account)
      product = product_fixture(account, %{status: "active"})
      membership = product_collection_membership_fixture(account, collection, product)
      pat = get_pat(account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = delete(conn, "/v1/product_collection_memberships/#{membership.id}")

      assert conn.status == 403
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      collection = product_collection_fixture(user.default_account)
      product = product_fixture(user.default_account)
      membership = product_collection_membership_fixture(user.default_account, collection, product)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = delete(conn, "/v1/product_collection_memberships/#{membership.id}")

      assert conn.status == 204
    end
  end
end
