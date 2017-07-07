defmodule BlueJet.ExternalFileCollectionControllerTest do
  use BlueJet.ConnCase

  alias BlueJet.User
  alias BlueJet.UserRegistration
  alias BlueJet.Authentication

  alias BlueJet.ExternalFileCollection
  alias BlueJet.ExternalFileCollectionMembership
  alias BlueJet.ExternalFile
  alias BlueJet.Sku
  alias BlueJet.Repo

  @valid_attrs %{
    "label" => "primary_images"
  }
  @invalid_attrs %{
    "label" => ""
  }

  setup do
    {_, %User{ default_account_id: account1_id }} = UserRegistration.sign_up(%{
      first_name: Faker.Name.first_name(),
      last_name: Faker.Name.last_name(),
      email: "test1@example.com",
      password: "test1234",
      account_name: Faker.Company.name()
    })
    {:ok, %{ access_token: uat1 }} = Authentication.get_token(%{ username: "test1@example.com", password: "test1234", scope: "type:user" })

    conn = build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{ conn: conn, uat1: uat1, account1_id: account1_id }
  end

  describe "POST /v1/external_file_collections" do
    test "with no access token", %{ conn: conn } do
      conn = post(conn, external_file_collection_path(conn, :create), %{
        "data" => %{
          "type" => "ExternalFileCollection",
          "attributes" => @valid_attrs
        }
      })

      assert conn.status == 401
    end

    test "with invalid attrs", %{ conn: conn, uat1: uat1 } do
      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = post(conn, external_file_collection_path(conn, :create), %{
        "data" => %{
          "type" => "ExternalFileCollection",
          "attributes" => @invalid_attrs
        }
      })

      assert json_response(conn, 422)["errors"]
      assert length(json_response(conn, 422)["errors"]) > 0
    end

    test "with valid attrs", %{ conn: conn, uat1: uat1 } do
      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = post(conn, external_file_collection_path(conn, :create), %{
        "data" => %{
          "type" => "ExternalFileCollection",
          "attributes" => @valid_attrs
        }
      })

      assert json_response(conn, 201)["data"]["id"]
      assert json_response(conn, 201)["data"]["attributes"]["label"] == @valid_attrs["label"]
    end

    test "with valid attrs and include", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      %Sku{ id: sku_id } = Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Orange",
        print_name: "ORANGE",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = post(conn, external_file_collection_path(conn, :create, include: "sku"), %{
        "data" => %{
          "type" => "ExternalFileCollection",
          "attributes" => @valid_attrs,
          "relationships" => %{
            "sku" => %{
              "data" => %{
                "type" => "Sku",
                "id" => sku_id
              }
            }
          }
        }
      })

      assert json_response(conn, 201)["data"]["id"]
      assert json_response(conn, 201)["data"]["attributes"]["label"] == @valid_attrs["label"]
      assert json_response(conn, 201)["data"]["relationships"]["sku"]["data"]["id"]
      assert length(Enum.filter(json_response(conn, 201)["included"], fn(item) -> item["type"] == "Sku" end)) == 1
    end
  end

  describe "GET /v1/external_file_collections/:id" do
    test "with no access token", %{ conn: conn } do
      conn = get(conn, external_file_collection_path(conn, :show, "test"))

      assert conn.status == 401
    end

    test "with with access token of a different account", %{ conn: conn, uat1: uat1 } do
      {_, %User{ default_account_id: account2_id }} = UserRegistration.sign_up(%{
        first_name: Faker.Name.first_name(),
        last_name: Faker.Name.last_name(),
        email: "test2@example.com",
        password: "test1234",
        account_name: Faker.Company.name()
      })

      efc = Repo.insert!(%ExternalFileCollection{
        account_id: account2_id,
        label: "primary_images"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      assert_error_sent(404, fn ->
        get(conn, external_file_collection_path(conn, :show, efc.id))
      end)
    end

    test "with valid access token and id", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      %ExternalFileCollection{ id: efc_id } = Repo.insert!(%ExternalFileCollection{
        account_id: account1_id,
        label: "primary_images",
        custom_data: %{
          "cd1" => "Custom Content"
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, external_file_collection_path(conn, :show, efc_id))

      assert json_response(conn, 200)["data"]["id"] == efc_id
      assert json_response(conn, 200)["data"]["attributes"]["label"] == "primary_images"
      assert json_response(conn, 200)["data"]["attributes"]["customData"]["cd1"] == "Custom Content"
    end

    test "with valid access token, id and locale", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      %ExternalFileCollection{ id: efc_id } = Repo.insert!(%ExternalFileCollection{
        name: "Primary Image",
        account_id: account1_id,
        label: "primary_images",
        custom_data: %{
          "cd1" => "Custom Content"
        },
        translations: %{
          "zh-CN" => %{
            "name" => "主要图片"
          }
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, external_file_collection_path(conn, :show, efc_id, locale: "zh-CN"))

      assert json_response(conn, 200)["data"]["id"] == efc_id
      assert json_response(conn, 200)["data"]["attributes"]["name"] == "主要图片"
      assert json_response(conn, 200)["data"]["attributes"]["label"] == "primary_images"
      assert json_response(conn, 200)["data"]["attributes"]["customData"]["cd1"] == "Custom Content"
    end

    test "with valid access token, id and include", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      %ExternalFile{ id: file1_id } = Repo.insert!(%ExternalFile{
        account_id: account1_id,
        name: Faker.Lorem.word(),
        status: "uploaded",
        content_type: "image/png",
        size_bytes: 42
      })
      %ExternalFile{ id: file2_id } = Repo.insert!(%ExternalFile{
        account_id: account1_id,
        name: Faker.Lorem.word(),
        status: "uploaded",
        content_type: "image/png",
        size_bytes: 42
      })
      %Sku{ id: sku_id } = Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Orange",
        print_name: "ORANGE",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      %ExternalFileCollection{ id: efc_id } = Repo.insert!(%ExternalFileCollection{
        name: "Primary Image",
        account_id: account1_id,
        sku_id: sku_id,
        label: "primary_images"
      })
      Repo.insert!(%ExternalFileCollectionMembership{
        account_id: account1_id,
        collection_id: efc_id,
        file_id: file1_id
      })
      Repo.insert!(%ExternalFileCollectionMembership{
        account_id: account1_id,
        collection_id: efc_id,
        file_id: file2_id
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, external_file_collection_path(conn, :show, efc_id, include: "sku,files"))

      assert json_response(conn, 200)["data"]["id"] == efc_id
      assert json_response(conn, 200)["data"]["attributes"]["label"] == "primary_images"
      assert json_response(conn, 200)["data"]["relationships"]["sku"]["data"]["id"]
      assert length(json_response(conn, 200)["data"]["relationships"]["files"]["data"]) == 2
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "Sku" end)) == 1
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "ExternalFile" end)) == 2
    end
  end

  describe "PATCH /v1/external_file_collections/:id" do
    test "with no access token", %{ conn: conn } do
      conn = patch(conn, external_file_collection_path(conn, :update, "test"), %{
        "data" => %{
          "id" => "test",
          "type" => "ExternalFileCollection",
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

      efc = Repo.insert!(%ExternalFileCollection{
        account_id: account2_id,
        label: "secondary_images"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      assert_error_sent(404, fn ->
        patch(conn, external_file_collection_path(conn, :update, efc.id), %{
          "data" => %{
            "id" => efc.id,
            "type" => "ExternalFileCollection",
            "attributes" => @valid_attrs
          }
        })
      end)
    end

    test "with good access token but invalid attrs", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      efc = Repo.insert!(%ExternalFileCollection{
        account_id: account1_id,
        label: "primary_images"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = patch(conn, external_file_collection_path(conn, :update, efc.id), %{
        "data" => %{
          "id" => efc.id,
          "type" => "ExternalFileCollection",
          "attributes" => @invalid_attrs
        }
      })

      assert json_response(conn, 422)["errors"]
      assert length(json_response(conn, 422)["errors"]) > 0
    end

    test "with good access token and valid attrs", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      efc = Repo.insert!(%ExternalFileCollection{
        account_id: account1_id,
        label: "secondary_images"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = patch(conn, external_file_collection_path(conn, :update, efc.id), %{
        "data" => %{
          "id" => efc.id,
          "type" => "ExternalFileCollection",
          "attributes" => @valid_attrs
        }
      })

      assert json_response(conn, 200)["data"]["id"]
      assert json_response(conn, 200)["data"]["attributes"]["label"] == @valid_attrs["label"]
    end

    test "with good access token, valid attrs and locale", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      efc = Repo.insert!(%ExternalFileCollection{
        name: "Primary Images",
        account_id: account1_id,
        label: "primary_images"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = patch(conn, external_file_collection_path(conn, :update, efc.id, locale: "zh-CN"), %{
        "data" => %{
          "id" => efc.id,
          "type" => "ExternalFileCollection",
          "attributes" => %{
            "name" => "主要图片"
          }
        }
      })

      assert json_response(conn, 200)["data"]["id"] == efc.id
      assert json_response(conn, 200)["data"]["attributes"]["name"] == "主要图片"
    end

    test "with good access token, valid attrs and include", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      %ExternalFile{ id: file1_id } = Repo.insert!(%ExternalFile{
        account_id: account1_id,
        name: Faker.Lorem.word(),
        status: "uploaded",
        content_type: "image/png",
        size_bytes: 42
      })
      %ExternalFile{ id: file2_id } = Repo.insert!(%ExternalFile{
        account_id: account1_id,
        name: Faker.Lorem.word(),
        status: "uploaded",
        content_type: "image/png",
        size_bytes: 42
      })
      %Sku{ id: sku_id } = Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Orange",
        print_name: "ORANGE",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      %ExternalFileCollection{ id: efc_id } = Repo.insert!(%ExternalFileCollection{
        name: "Primary Image",
        account_id: account1_id,
        sku_id: sku_id,
        label: "secondary_images"
      })
      Repo.insert!(%ExternalFileCollectionMembership{
        account_id: account1_id,
        collection_id: efc_id,
        file_id: file1_id
      })
      Repo.insert!(%ExternalFileCollectionMembership{
        account_id: account1_id,
        collection_id: efc_id,
        file_id: file2_id
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = patch(conn, external_file_collection_path(conn, :update, efc_id, include: "sku,files"), %{
        "data" => %{
          "id" => efc_id,
          "type" => "ExternalFileCollection",
          "attributes" => %{
            label: "primary_images"
          }
        }
      })

      assert json_response(conn, 200)["data"]["id"] == efc_id
      assert json_response(conn, 200)["data"]["attributes"]["label"] == "primary_images"
      assert json_response(conn, 200)["data"]["relationships"]["sku"]["data"]["id"]
      assert length(json_response(conn, 200)["data"]["relationships"]["files"]["data"]) == 2
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "Sku" end)) == 1
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "ExternalFile" end)) == 2
    end
  end

  describe "GET /v1/external_file_collections" do
    test "with no access token", %{ conn: conn } do
      conn = get(conn, external_file_collection_path(conn, :index))

      assert conn.status == 401
    end

    test "with good access token", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      {_, %User{ default_account_id: account2_id }} = UserRegistration.sign_up(%{
        first_name: Faker.Name.first_name(),
        last_name: Faker.Name.last_name(),
        email: "test2@example.com",
        password: "test1234",
        account_name: Faker.Company.name()
      })

      Repo.insert!(%ExternalFileCollection{
        account_id: account2_id,
        label: "primary_images"
      })
      Repo.insert!(%ExternalFileCollection{
        account_id: account1_id,
        label: "primary_images"
      })
      Repo.insert!(%ExternalFileCollection{
        account_id: account1_id,
        label: "secondary_images"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, external_file_collection_path(conn, :index))

      assert length(json_response(conn, 200)["data"]) == 2
    end

    test "with good access token and locale", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      Repo.insert!(%ExternalFileCollection{
        name: "Primary Image",
        account_id: account1_id,
        label: "primary_images",
        translations: %{
          "zh-CN" => %{
            "name" => "主要图片"
          }
        }
      })
      Repo.insert!(%ExternalFileCollection{
        name: "Primary Image",
        account_id: account1_id,
        label: "primary_images"
      })
      Repo.insert!(%ExternalFileCollection{
        name: "Primary Image",
        account_id: account1_id,
        label: "secondary_images"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, external_file_collection_path(conn, :index, locale: "zh-CN"))

      assert length(json_response(conn, 200)["data"]) == 3
      assert json_response(conn, 200)["meta"]["resultCount"] == 3
      assert json_response(conn, 200)["meta"]["totalCount"] == 3
      assert length(Enum.filter(json_response(conn, 200)["data"], fn(item) -> item["attributes"]["name"] == "主要图片" end)) == 1
    end

    @tag :focus
    test "with good access token and include", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      %ExternalFile{ id: file1_id } = Repo.insert!(%ExternalFile{
        account_id: account1_id,
        name: Faker.Lorem.word(),
        status: "uploaded",
        content_type: "image/png",
        size_bytes: 42
      })
      %ExternalFile{ id: file2_id } = Repo.insert!(%ExternalFile{
        account_id: account1_id,
        name: Faker.Lorem.word(),
        status: "uploaded",
        content_type: "image/png",
        size_bytes: 42
      })
      %Sku{ id: sku_id } = Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Orange",
        print_name: "ORANGE",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })
      %ExternalFileCollection{ id: efc_id } = Repo.insert!(%ExternalFileCollection{
        name: "Primary Image",
        account_id: account1_id,
        sku_id: sku_id,
        label: "secondary_images"
      })
      Repo.insert!(%ExternalFileCollectionMembership{
        account_id: account1_id,
        collection_id: efc_id,
        file_id: file1_id
      })
      Repo.insert!(%ExternalFileCollectionMembership{
        account_id: account1_id,
        collection_id: efc_id,
        file_id: file2_id
      })

      Repo.insert!(%ExternalFileCollection{
        name: "Primary Image",
        account_id: account1_id,
        label: "primary_images"
      })
      Repo.insert!(%ExternalFileCollection{
        name: "Primary Image",
        account_id: account1_id,
        label: "primary_images"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, external_file_collection_path(conn, :index, include: "sku,files"))

      assert length(json_response(conn, 200)["data"]) == 3
      assert json_response(conn, 200)["meta"]["resultCount"] == 3
      assert json_response(conn, 200)["meta"]["totalCount"] == 3
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "Sku" end)) == 1
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "ExternalFile" end)) == 2
    end

    test "with good access token and pagination", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      Repo.insert!(%ExternalFileCollection{
        account_id: account1_id,
        label: "primary_images"
      })
      Repo.insert!(%ExternalFileCollection{
        account_id: account1_id,
        label: "primary_images"
      })
      Repo.insert!(%ExternalFileCollection{
        account_id: account1_id,
        label: "secondary_images"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, external_file_collection_path(conn, :index, %{ "page[number]" => 2, "page[size]" => 1 }))

      assert length(json_response(conn, 200)["data"]) == 1
      assert json_response(conn, 200)["meta"]["resultCount"] == 3
      assert json_response(conn, 200)["meta"]["totalCount"] == 3
    end

    test "with good access token and search", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      Repo.insert!(%ExternalFileCollection{
        name: "Primary Images",
        account_id: account1_id,
        label: "primary_images"
      })
      Repo.insert!(%ExternalFileCollection{
        name: "primary images",
        account_id: account1_id,
        label: "primary_images"
      })
      Repo.insert!(%ExternalFileCollection{
        name: "seconary images",
        account_id: account1_id,
        label: "secondary_images"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, external_file_collection_path(conn, :index, search: "pri"))

      assert length(json_response(conn, 200)["data"]) == 2
      assert json_response(conn, 200)["meta"]["resultCount"] == 2
      assert json_response(conn, 200)["meta"]["totalCount"] == 3
    end
  end

  describe "DELETE /v1/external_file_collections/:id" do
    test "with no access token", %{ conn: conn } do
      conn = delete(conn, external_file_collection_path(conn, :delete, "test"))

      assert conn.status == 401
    end

    test "with with access token of a different account", %{ conn: conn, uat1: uat1 } do
      {_, %User{ default_account_id: account2_id }} = UserRegistration.sign_up(%{
        first_name: Faker.Name.first_name(),
        last_name: Faker.Name.last_name(),
        email: "test2@example.com",
        password: "test1234",
        account_name: Faker.Company.name()
      })

      efc = Repo.insert!(%ExternalFileCollection{
        account_id: account2_id,
        label: "secondary_images"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      assert_error_sent(404, fn ->
        delete(conn, external_file_collection_path(conn, :delete, efc.id))
      end)
    end

    test "with valid access token and id", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      efc = Repo.insert!(%ExternalFileCollection{
        account_id: account1_id,
        label: "secondary_images"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = delete(conn, external_file_collection_path(conn, :delete, efc.id))

      assert conn.status == 204
    end
  end
end
