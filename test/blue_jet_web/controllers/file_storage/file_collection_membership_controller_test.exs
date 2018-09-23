defmodule BlueJetWeb.FileCollectionMembershipControllerTest do
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

  # List file collection membership
  describe "GET /v1/file_collections/:id/memberships" do
    test "without access token", %{conn: conn} do
      conn = get(conn, "/v1/file_collections/#{UUID.generate()}/memberships")

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      account = account_fixture()
      collection = file_collection_fixture(account)

      file1 = file_fixture(account, %{status: "uploaded"})
      file2 = file_fixture(account, %{status: "uploaded"})
      file3 = file_fixture(account)

      file_collection_membership_fixture(account, collection, file1)
      file_collection_membership_fixture(account, collection, file2)
      file_collection_membership_fixture(account, collection, file3)

      pat = get_pat(account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = get(conn, "/v1/file_collections/#{collection.id}/memberships")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      collection = file_collection_fixture(user.default_account)

      file1 = file_fixture(user.default_account, %{status: "uploaded"})
      file2 = file_fixture(user.default_account, %{status: "uploaded"})
      file3 = file_fixture(user.default_account)

      file_collection_membership_fixture(user.default_account, collection, file1)
      file_collection_membership_fixture(user.default_account, collection, file2)
      file_collection_membership_fixture(user.default_account, collection, file3)

      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/file_collections/#{collection.id}/memberships")

      response = json_response(conn, 200)
      assert length(response["data"]) == 3
    end
  end

  # Create a file collection membership
  describe "POST /v1/file_collections/:id/memberships" do
    test "without access token", %{conn: conn} do
      conn = post(conn, "/v1/file_collections/#{UUID.generate()}/memberships", %{
        "data" => %{
          "type" => "FileCollectionMembership"
        }
      })

      assert conn.status == 401
    end

    test "with valid attributes", %{conn: conn} do
      user = standard_user_fixture()
      collection = file_collection_fixture(user.default_account)
      file = file_fixture(user.default_account)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/file_collections/#{collection.id}/memberships", %{
        "data" => %{
          "type" => "FileCollectionMembership",
          "relationships" => %{
            "collection" => %{
              "data" => %{
                "id" => collection.id,
                "type" => "FileCollection"
              }
            },
            "file" => %{
              "data" => %{
                "id" => file.id,
                "type" => "File"
              }
            }
          }
        }
      })

      assert json_response(conn, 201)
    end
  end

  # Retrieve a file collection membership
  describe "GET /v1/file_collection_memberships/:id" do
    test "without access token", %{conn: conn} do
      conn = get(conn, "/v1/file_collection_memberships/#{UUID.generate()}")

      assert conn.status == 401
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      collection = file_collection_fixture(user.default_account)
      file = file_fixture(user.default_account)
      membership = file_collection_membership_fixture(user.default_account, collection, file)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/file_collection_memberships/#{membership.id}")

      assert json_response(conn, 200)
    end
  end

  # Update a file collection membership
  describe "PATCH /v1/file_collection_memberships/:id" do
    test "without access token", %{conn: conn} do
      conn = patch(conn, "/v1/file_collection_memberships/#{UUID.generate()}", %{
        "data" => %{
          "type" => "FileCollectionMembership",
          "attributes" => %{
            "sortIndex" => System.unique_integer([:positive])
          }
        }
      })

      assert conn.status == 401
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      collection = file_collection_fixture(user.default_account)
      file = file_fixture(user.default_account)
      membership = file_collection_membership_fixture(user.default_account, collection, file)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/file_collection_memberships/#{membership.id}", %{
        "data" => %{
          "id" => membership.id,
          "type" => "FileCollectionMembership",
          "attributes" => %{
            "sortIndex" => System.unique_integer([:positive])
          }
        }
      })

      assert json_response(conn, 200)
    end
  end

  # Delete a file collection membership
  describe "DELETE /v1/file_collection_memberships/:id" do
    test "without access token", %{conn: conn} do
      conn = delete(conn, "/v1/file_collection_memberships/#{UUID.generate()}")

      assert conn.status == 401
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      collection = file_collection_fixture(user.default_account)
      file = file_fixture(user.default_account)
      membership = file_collection_membership_fixture(user.default_account, collection, file)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = delete(conn, "/v1/file_collection_memberships/#{membership.id}")

      assert conn.status == 204
    end
  end
end
