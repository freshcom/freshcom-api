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
      name: "Primary Images",
      label: "primary_images",
      translations: %{
        "zh-CN" => %{
          "name" => "主要图片"
        }
      }
    })

    %ExternalFile{ id: ef1_id } = Repo.insert!(%ExternalFile{
      account_id: account1_id,
      name: Faker.Lorem.word(),
      status: "uploaded",
      content_type: "image/png",
      size_bytes: 42
    })

    conn = build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{ conn: conn, uat1: uat1, account1_id: account1_id, efc1_id: efc1_id, ef1_id: ef1_id }
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

    test "with missing rels", %{ conn: conn, uat1: uat1, efc1_id: efc1_id } do
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

    test "with invalid rels", %{ conn: conn, uat1: uat1, efc1_id: efc1_id } do
      {_, %User{ default_account_id: account2_id }} = UserRegistration.sign_up(%{
        first_name: Faker.Name.first_name(),
        last_name: Faker.Name.last_name(),
        email: "test2@example.com",
        password: "test1234",
        account_name: Faker.Company.name()
      })

      %ExternalFile{ id: ef2_id } = Repo.insert!(%ExternalFile{
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
                "id" => ef2_id
              }
            }
          }
        }
      })

      assert json_response(conn, 422)["errors"]
      assert length(json_response(conn, 422)["errors"]) > 0
    end

    test "with valid attrs and rels", %{ conn: conn, uat1: uat1, efc1_id: efc1_id, ef1_id: ef1_id } do
      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = post(conn, "/v1/external_file_collections/#{efc1_id}/memberships", %{
        "data" => %{
          "type" => "ExternalFileCollectionMembership",
          "attributes" => @valid_attrs,
          "relationships" => %{
            "file": %{
              "data" => %{
                "type" => "ExternalFile",
                "id" => ef1_id
              }
            }
          }
        }
      })

      assert json_response(conn, 201)["data"]["id"]
      assert json_response(conn, 201)["data"]["attributes"]["sortIndex"]
      assert json_response(conn, 201)["data"]["relationships"]["collection"]["data"]["id"] == efc1_id
      assert json_response(conn, 201)["data"]["relationships"]["file"]["data"]["id"] == ef1_id
    end

    test "with valid attrs, rels and include", %{ conn: conn, uat1: uat1, efc1_id: efc1_id, ef1_id: ef1_id } do
      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = post(conn, "/v1/external_file_collections/#{efc1_id}/memberships?include=file,collection", %{
        "data" => %{
          "type" => "ExternalFileCollectionMembership",
          "attributes" => @valid_attrs,
          "relationships" => %{
            "file": %{
              "data" => %{
                "type" => "ExternalFile",
                "id" => ef1_id
              }
            }
          }
        }
      })

      assert json_response(conn, 201)["data"]["id"]
      assert json_response(conn, 201)["data"]["attributes"]["sortIndex"]
      assert json_response(conn, 201)["data"]["relationships"]["collection"]["data"]["id"] == efc1_id
      assert json_response(conn, 201)["data"]["relationships"]["file"]["data"]["id"] == ef1_id
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

    test "with access token of a different account", %{ conn: conn, uat1: uat1 } do
      {_, %User{ default_account_id: account2_id }} = UserRegistration.sign_up(%{
        first_name: Faker.Name.first_name(),
        last_name: Faker.Name.last_name(),
        email: "test2@example.com",
        password: "test1234",
        account_name: Faker.Company.name()
      })

      %ExternalFile{ id: ef2_id } = Repo.insert!(%ExternalFile{
        account_id: account2_id,
        name: Faker.Lorem.word(),
        status: "uploaded",
        content_type: "image/png",
        size_bytes: 42
      })

      %ExternalFileCollection{ id: efc2_id } = Repo.insert!(%ExternalFileCollection{
        account_id: account2_id,
        label: "primary_images"
      })

      %ExternalFileCollectionMembership{ id: efcm2_id } = Repo.insert!(%ExternalFileCollectionMembership{
        account_id: account2_id,
        collection_id: efc2_id,
        file_id: ef2_id
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      assert_error_sent(404, fn ->
        patch(conn, "/v1/external_file_collection_memberships/#{efcm2_id}", %{
          "data" => %{
            "id" => efcm2_id,
            "type" => "ExternalFileCollectionMembership",
            "attributes" => @valid_attrs
          }
        })
      end)
    end

    test "with valid attrs and rels", %{ conn: conn, uat1: uat1, account1_id: account1_id, efc1_id: efc1_id, ef1_id: ef1_id } do
      %ExternalFileCollectionMembership{ id: efcm1_id } = Repo.insert!(%ExternalFileCollectionMembership{
        account_id: account1_id,
        collection_id: efc1_id,
        file_id: ef1_id
      })

      %ExternalFile{ id: ef2_id } = Repo.insert!(%ExternalFile{
        account_id: account1_id,
        name: Faker.Lorem.word(),
        status: "uploaded",
        content_type: "image/png",
        size_bytes: 42
      })

      %ExternalFileCollection{ id: efc2_id } = Repo.insert!(%ExternalFileCollection{
        account_id: account1_id,
        label: "primary_images"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = patch(conn, "/v1/external_file_collection_memberships/#{efcm1_id}", %{
        "data" => %{
          "type" => "ExternalFileCollectionMembership",
          "attributes" => @valid_attrs,
          "relationships" => %{
            "file": %{
              "data" => %{
                "type" => "ExternalFile",
                "id" => ef2_id
              }
            },
            "collection": %{
              "data" => %{
                "type" => "ExternalFile",
                "id" => efc2_id
              }
            }
          }
        }
      })

      assert json_response(conn, 200)["data"]["id"]
      assert json_response(conn, 200)["data"]["attributes"]["sortIndex"]
      assert json_response(conn, 200)["data"]["relationships"]["collection"]["data"]["id"] == efc1_id
      assert json_response(conn, 200)["data"]["relationships"]["file"]["data"]["id"] == ef1_id
    end

    @tag :focus
    test "with valid attrs, rels, locale and include", %{ conn: conn, uat1: uat1, account1_id: account1_id, efc1_id: efc1_id, ef1_id: ef1_id } do
      %ExternalFileCollectionMembership{ id: efcm1_id } = Repo.insert!(%ExternalFileCollectionMembership{
        account_id: account1_id,
        collection_id: efc1_id,
        file_id: ef1_id
      })

      %ExternalFile{ id: ef2_id } = Repo.insert!(%ExternalFile{
        account_id: account1_id,
        name: Faker.Lorem.word(),
        status: "uploaded",
        content_type: "image/png",
        size_bytes: 42
      })

      %ExternalFileCollection{ id: efc2_id } = Repo.insert!(%ExternalFileCollection{
        account_id: account1_id,
        label: "primary_images"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = patch(conn, "/v1/external_file_collection_memberships/#{efcm1_id}?locale=zh-CN&include=file,collection", %{
        "data" => %{
          "type" => "ExternalFileCollectionMembership",
          "attributes" => @valid_attrs,
          "relationships" => %{
            "file": %{
              "data" => %{
                "type" => "ExternalFile",
                "id" => ef2_id
              }
            },
            "collection": %{
              "data" => %{
                "type" => "ExternalFile",
                "id" => efc2_id
              }
            }
          }
        }
      })

      assert json_response(conn, 200)["data"]["id"]
      assert json_response(conn, 200)["data"]["attributes"]["sortIndex"]
      assert json_response(conn, 200)["data"]["relationships"]["collection"]["data"]["id"] == efc1_id
      assert json_response(conn, 200)["data"]["relationships"]["file"]["data"]["id"] == ef1_id
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "ExternalFile" end)) == 1
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "ExternalFileCollection" end)) == 1
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["attributes"]["name"] == "主要图片" end)) == 1
    end
  end

  describe "GET /v1/external_file_collection_memberships" do
    test "with no access token", %{ conn: conn } do
      conn = get(conn, sku_path(conn, :index))

      assert conn.status == 401
    end

    test "with good access token", %{ conn: conn, uat1: uat1, account1_id: account1_id, efc1_id: efc1_id, ef1_id: ef1_id } do
      {_, %User{ default_account_id: account2_id }} = UserRegistration.sign_up(%{
        first_name: Faker.Name.first_name(),
        last_name: Faker.Name.last_name(),
        email: "test2@example.com",
        password: "test1234",
        account_name: Faker.Company.name()
      })

      %ExternalFile{ id: ef2_id } = Repo.insert!(%ExternalFile{
        account_id: account2_id,
        name: Faker.Lorem.word(),
        status: "uploaded",
        content_type: "image/png",
        size_bytes: 42
      })

      %ExternalFileCollection{ id: efc2_id } = Repo.insert!(%ExternalFileCollection{
        account_id: account2_id,
        label: "primary_images"
      })

      Repo.insert!(%ExternalFileCollectionMembership{
        account_id: account2_id,
        collection_id: efc2_id,
        file_id: ef2_id
      })

      Repo.insert!(%ExternalFileCollectionMembership{
        account_id: account1_id,
        collection_id: efc1_id,
        file_id: ef1_id
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, external_file_collection_membership_path(conn, :index))

      assert length(json_response(conn, 200)["data"]) == 1
      assert json_response(conn, 200)["meta"]["resultCount"] == 1
      assert json_response(conn, 200)["meta"]["totalCount"] == 1
    end

    test "with good access token, locale and include", %{ conn: conn, uat1: uat1, account1_id: account1_id, efc1_id: efc1_id, ef1_id: ef1_id } do
      Repo.insert!(%ExternalFileCollectionMembership{
        account_id: account1_id,
        collection_id: efc1_id,
        file_id: ef1_id
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, external_file_collection_membership_path(conn, :index, include: "collection,file", locale: "zh-CN"))

      assert length(json_response(conn, 200)["data"]) == 1
      assert json_response(conn, 200)["meta"]["resultCount"] == 1
      assert json_response(conn, 200)["meta"]["totalCount"] == 1
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "ExternalFile" end)) == 1
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "ExternalFileCollection" end)) == 1
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["attributes"]["name"] == "主要图片" end)) == 1
    end

    test "with good access token, locale, include and filter", %{ conn: conn, uat1: uat1, account1_id: account1_id, efc1_id: efc1_id, ef1_id: ef1_id } do
      %ExternalFile{ id: ef2_id } = Repo.insert!(%ExternalFile{
        account_id: account1_id,
        name: Faker.Lorem.word(),
        status: "uploaded",
        content_type: "image/png",
        size_bytes: 42
      })

      %ExternalFileCollection{ id: efc2_id } = Repo.insert!(%ExternalFileCollection{
        account_id: account1_id,
        label: "primary_images"
      })

      Repo.insert!(%ExternalFileCollectionMembership{
        account_id: account1_id,
        collection_id: efc2_id,
        file_id: ef2_id
      })

      Repo.insert!(%ExternalFileCollectionMembership{
        account_id: account1_id,
        collection_id: efc1_id,
        file_id: ef1_id
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, external_file_collection_membership_path(conn, :index, filter: %{ "collectionId" => efc1_id }, include: "collection,file", locale: "zh-CN"))

      assert length(json_response(conn, 200)["data"]) == 1
      assert json_response(conn, 200)["meta"]["resultCount"] == 1
      assert json_response(conn, 200)["meta"]["totalCount"] == 2
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "ExternalFile" end)) == 1
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "ExternalFileCollection" end)) == 1
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["attributes"]["name"] == "主要图片" end)) == 1
    end
  end

  describe "DELETE /v1/external_file_collection_memberships/:id" do
    test "with no access token", %{ conn: conn } do
      conn = delete(conn, external_file_collection_membership_path(conn, :delete, "test"))

      assert conn.status == 401
    end

    test "with access token of a different account", %{ conn: conn, uat1: uat1 } do
      {_, %User{ default_account_id: account2_id }} = UserRegistration.sign_up(%{
        first_name: Faker.Name.first_name(),
        last_name: Faker.Name.last_name(),
        email: "test2@example.com",
        password: "test1234",
        account_name: Faker.Company.name()
      })

      %ExternalFile{ id: ef2_id } = Repo.insert!(%ExternalFile{
        account_id: account2_id,
        name: Faker.Lorem.word(),
        status: "uploaded",
        content_type: "image/png",
        size_bytes: 42
      })

      %ExternalFileCollection{ id: efc2_id } = Repo.insert!(%ExternalFileCollection{
        account_id: account2_id,
        label: "primary_images"
      })

      %ExternalFileCollectionMembership{ id: efcm2_id } = Repo.insert!(%ExternalFileCollectionMembership{
        account_id: account2_id,
        collection_id: efc2_id,
        file_id: ef2_id
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      assert_error_sent(404, fn ->
        delete(conn, external_file_collection_membership_path(conn, :delete, efcm2_id))
      end)
    end

    test "with valid access token and id", %{ conn: conn, uat1: uat1, account1_id: account1_id, efc1_id: efc1_id, ef1_id: ef1_id } do
      %ExternalFileCollectionMembership{ id: efcm1_id } = Repo.insert!(%ExternalFileCollectionMembership{
        account_id: account1_id,
        collection_id: efc1_id,
        file_id: ef1_id
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = delete(conn, external_file_collection_membership_path(conn, :delete, efcm1_id))

      assert conn.status == 204
    end
  end
end
