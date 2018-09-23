defmodule BlueJetWeb.FileCollectionControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper
  import BlueJet.FileStorage.TestHelper

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{conn: conn}
  end

  # List file collection
  describe "GET /v1/file_collections" do
    test "without access token", %{conn: conn} do
      conn = get(conn, "/v1/file_collections")

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      account = account_fixture()
      owner = %{id: UUID.generate(), type: "OwnerType"}
      file_collection_fixture(account, %{owner_id: owner.id, owner_type: owner.type})
      file_collection_fixture(account, %{owner_id: owner.id, owner_type: owner.type})
      file_collection_fixture(account)
      pat = get_pat(account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = get(conn, "/v1/file_collections?filter[ownerId]=#{owner.id}&filter[ownerType]=#{owner.type}")

      response = json_response(conn, 200)

      assert length(response["data"]) == 2
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      file_collection_fixture(user.default_account)
      file_collection_fixture(user.default_account)
      file_collection_fixture(user.default_account)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/file_collections")

      response = json_response(conn, 200)

      assert length(response["data"]) == 3
    end
  end

  # Create a file collection
  describe "POST /v1/file_collections" do
    test "without access token", %{conn: conn} do
      conn = post(conn, "/v1/file_collections", %{
        "data" => %{
          "type" => "FileCollection"
        }
      })

      assert conn.status == 401
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/file_collections", %{
        "data" => %{
          "type" => "FileCollection",
          "attributes" => %{
            "name" => Faker.Commerce.product_name()
          }
        }
      })

      assert json_response(conn, 201)
    end
  end

  # Retrieve a file collection
  describe "GET /v1/file_collections/:id" do
    test "without access token", %{conn: conn} do
      conn = get(conn, "/v1/file_collections/#{UUID.generate()}")

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      account = account_fixture()
      collection = file_collection_fixture(account, %{status: "active"})
      pat = get_pat(account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = get(conn, "/v1/file_collections/#{collection.id}")

      assert json_response(conn, 200)
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      collection = file_collection_fixture(user.default_account)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/file_collections/#{collection.id}")

      assert json_response(conn, 200)
    end
  end

  # Update a file collection
  describe "PATCH /v1/file_collections/:id" do
    test "without access token", %{conn: conn} do
      conn = patch(conn, "/v1/file_collections/#{UUID.generate()}", %{
        "data" => %{
          "type" => "File",
          "attributes" => %{
            "name" => nil
          }
        }
      })

      assert conn.status == 401
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      collection = file_collection_fixture(user.default_account)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/file_collections/#{collection.id}", %{
        "data" => %{
          "type" => "FileCollection",
          "attributes" => %{
            "name" => Faker.Commerce.product_name()
          }
        }
      })

      assert json_response(conn, 200)
    end
  end

  # Delete a file collection
  describe "DELETE /v1/file_collections/:id" do
    test "without access token", %{conn: conn} do
      conn = delete(conn, "/v1/file_collections/#{UUID.generate()}")

      assert conn.status == 401
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      collection = file_collection_fixture(user.default_account)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = delete(conn, "/v1/file_collections/#{collection.id}")

      assert conn.status == 204
    end
  end
end
