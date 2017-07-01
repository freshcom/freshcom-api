defmodule BlueJet.ExternalFileCollectionMembershipControllerTest do
  use BlueJet.ConnCase

  alias BlueJet.User
  alias BlueJet.UserRegistration
  alias BlueJet.Authentication

  alias BlueJet.ExternalFileCollectionMembership
  alias BlueJet.ExternalFileCollection
  alias BlueJet.ExternalFile
  alias BlueJet.Repo

  @valid_attrs %{
    "sortIndex" => 1
  }
  @invalid_attrs %{}

  setup do
    {_, %User{ default_account_id: account1_id }} = UserRegistration.sign_up(%{
      first_name: Faker.Name.first_name(),
      last_name: Faker.Name.last_name(),
      email: "test1@example.com",
      password: "test1234",
      account_name: Faker.Company.name()
    })
    {:ok, %{ access_token: uat1 }} = Authentication.get_token(%{ username: "test1@example.com", password: "test1234", scope: "type:user" })

    %ExternalFileCollection{ id: efc1_id } = Repo.insert!(%ExternalFileCollection{
      account_id: account1_id,
      label: "primary_images"
    })

    conn = build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{ conn: conn, uat1: uat1, account1_id: account1_id, efc1_id: efc1_id }
  end

  describe "POST /v1/external_file_collections/:efc_id/memberships" do
    test "with no access token", %{ conn: conn, efc1_id: efc1_id } do
      conn = post(conn, "/v1/external_file_collections/#{efc1_id}/memberships", %{
        "data" => %{
          "type" => "ExternalFileCollectionMembership",
          "attributes" => @valid_attrs
        }
      })

      assert conn.status == 401
    end

    test "with missing relationship", %{ conn: conn, uat1: uat1, efc1_id: efc1_id } do
      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = post(conn, "/v1/external_file_collections/#{efc1_id}/memberships", %{
        "data" => %{
          "type" => "ExternalFileCollectionMembership",
          "attributes" => @invalid_attrs
        }
      })

      assert json_response(conn, 422)["errors"]
      assert length(json_response(conn, 422)["errors"]) > 0
    end

    test "with invalid relationship", %{ conn: conn, uat1: uat1, efc1_id: efc1_id } do
      {_, %User{ default_account_id: account2_id }} = UserRegistration.sign_up(%{
        first_name: Faker.Name.first_name(),
        last_name: Faker.Name.last_name(),
        email: "test2@example.com",
        password: "test1234",
        account_name: Faker.Company.name()
      })

      %ExternalFile{ id: file1_id } = Repo.insert!(%ExternalFile{
        account_id: account2_id,
        name: Faker.Lorem.word(),
        status: "uploaded",
        content_type: "image/png",
        size_bytes: 42
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = post(conn, "/v1/external_file_collections/#{efc1_id}/memberships", %{
        "data" => %{
          "type" => "ExternalFileCollectionMembership",
          "attributes" => @valid_attrs,
          "relationships" => %{
            "file": %{
              "data" => %{
                "type" => "ExternalFile",
                "id" => file1_id
              }
            }
          }
        }
      })

      assert json_response(conn, 422)["errors"]
      assert length(json_response(conn, 422)["errors"]) > 0
    end

    test "with valid relationship", %{ conn: conn, uat1: uat1, account1_id: account1_id, efc1_id: efc1_id } do
      %ExternalFile{ id: file1_id } = Repo.insert!(%ExternalFile{
        account_id: account1_id,
        name: Faker.Lorem.word(),
        status: "uploaded",
        content_type: "image/png",
        size_bytes: 42
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = post(conn, "/v1/external_file_collections/#{efc1_id}/memberships", %{
        "data" => %{
          "type" => "ExternalFileCollectionMembership",
          "attributes" => @valid_attrs,
          "relationships" => %{
            "file": %{
              "data" => %{
                "type" => "ExternalFile",
                "id" => file1_id
              }
            }
          }
        }
      })

      assert json_response(conn, 201)["data"]["id"]
      assert json_response(conn, 201)["data"]["attributes"]["sortIndex"]
      assert json_response(conn, 201)["data"]["relationships"]["collection"]["data"]["id"] == efc1_id
      assert json_response(conn, 201)["data"]["relationships"]["file"]["data"]["id"] == file1_id
    end

    test "with valid relationship and include", %{ conn: conn, uat1: uat1, account1_id: account1_id, efc1_id: efc1_id } do
      %ExternalFile{ id: file1_id } = Repo.insert!(%ExternalFile{
        account_id: account1_id,
        name: Faker.Lorem.word(),
        status: "uploaded",
        content_type: "image/png",
        size_bytes: 42
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = post(conn, "/v1/external_file_collections/#{efc1_id}/memberships?include=file,collection", %{
        "data" => %{
          "type" => "ExternalFileCollectionMembership",
          "attributes" => @valid_attrs,
          "relationships" => %{
            "file": %{
              "data" => %{
                "type" => "ExternalFile",
                "id" => file1_id
              }
            }
          }
        }
      })

      assert json_response(conn, 201)["data"]["id"]
      assert json_response(conn, 201)["data"]["attributes"]["sortIndex"]
      assert json_response(conn, 201)["data"]["relationships"]["collection"]["data"]["id"] == efc1_id
      assert json_response(conn, 201)["data"]["relationships"]["file"]["data"]["id"] == file1_id
      assert length(Enum.filter(json_response(conn, 201)["included"], fn(item) -> item["type"] == "ExternalFileCollection" end)) == 1
      assert length(Enum.filter(json_response(conn, 201)["included"], fn(item) -> item["type"] == "ExternalFile" end)) == 1
    end
  end

  describe "PATCH /v1/external_file_collection_memberships/:id" do
    test "with no access token", %{ conn: conn } do
      conn = patch(conn, "/v1/external_file_collection_memberships/#{Ecto.UUID.generate()}", %{
        "data" => %{
          "id" => "test",
          "type" => "ExternalFileCollectionMembership",
          "attributes" => @valid_attrs
        }
      })

      assert conn.status == 401
    end

    test "with access token of a different account", %{ conn: conn, uat1: uat1, efc1_id: efc1_id } do
      {_, %User{ default_account_id: account2_id }} = UserRegistration.sign_up(%{
        first_name: Faker.Name.first_name(),
        last_name: Faker.Name.last_name(),
        email: "test2@example.com",
        password: "test1234",
        account_name: Faker.Company.name()
      })

      %ExternalFile{ id: file1_id } = Repo.insert!(%ExternalFile{
        account_id: account2_id,
        name: Faker.Lorem.word(),
        status: "uploaded",
        content_type: "image/png",
        size_bytes: 42
      })

      %ExternalFileCollection{ id: efc1_id } = Repo.insert!(%ExternalFileCollection{
        account_id: account2_id,
        label: "primary_images"
      })

      %ExternalFileCollectionMembership{ id: efcm1_id } = Repo.insert!(%ExternalFileCollectionMembership{
        account_id: account2_id,
        collection_id: efc1_id,
        file_id: file1_id
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      assert_error_sent(404, fn ->
        patch(conn, "/v1/external_file_collection_memberships/#{efcm1_id}", %{
          "data" => %{
            "id" => efcm1_id,
            "type" => "ExternalFileCollectionMembership",
            "attributes" => @valid_attrs
          }
        })
      end)
    end
  end
end
