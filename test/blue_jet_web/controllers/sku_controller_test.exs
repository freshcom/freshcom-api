defmodule BlueJetWeb.SkuControllerTest do
  use BlueJetWeb.ConnCase

  alias BlueJet.Identity.User
  alias BlueJet.Identity

  alias BlueJet.Inventory.Sku
  alias BlueJet.FileStorage.File
  alias BlueJet.FileStorage.FileCollection
  alias BlueJet.FileStorage.FileCollectionMembership
  alias BlueJet.Repo

  @valid_attrs %{
    "status" => "active",
    "name" => "Apple",
    "printName" => "APPLE",
    "unitOfMeasure" => "EA",
    "customData" => %{
      "kind" => "Gala"
    }
  }
  @invalid_attrs %{
    "name" => ""
  }

  setup do
    {_, %User{ default_account_id: account1_id }} = Identity.create_user(%{
      fields: %{
        "first_name" => Faker.Name.first_name(),
        "last_name" => Faker.Name.last_name(),
        "email" => "test1@example.com",
        "password" => "test1234",
        "account_name" => Faker.Company.name()
      }
    })
    {:ok, %{ access_token: uat1 }} = Identity.authenticate(%{ username: "test1@example.com", password: "test1234", scope: "type:user" })

    conn = build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{ conn: conn, uat1: uat1, account1_id: account1_id }
  end

  describe "POST /v1/skus" do
    test "with no access token", %{ conn: conn } do
      conn = post(conn, "/v1/skus", %{
        "data" => %{
          "type" => "Sku",
          "attributes" => @valid_attrs
        }
      })

      assert conn.status == 401
    end

    test "with invalid attrs and rels", %{ conn: conn, uat1: uat1 } do
      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = post(conn, "/v1/skus", %{
        "data" => %{
          "type" => "Sku",
          "attributes" => @invalid_attrs
        }
      })

      assert json_response(conn, 422)["errors"]
      assert length(json_response(conn, 422)["errors"]) > 0
    end

    test "with valid attrs and rels", %{ conn: conn, uat1: uat1 } do
      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = post(conn, "/v1/skus", %{
        "data" => %{
          "type" => "Sku",
          "attributes" => @valid_attrs
        }
      })

      assert json_response(conn, 201)["data"]["id"]
      assert json_response(conn, 201)["data"]["attributes"]["status"] == @valid_attrs["status"]
      assert json_response(conn, 201)["data"]["attributes"]["name"] == @valid_attrs["name"]
      assert json_response(conn, 201)["data"]["attributes"]["printName"] == @valid_attrs["printName"]
      assert json_response(conn, 201)["data"]["attributes"]["unitOfMeasure"] == @valid_attrs["unitOfMeasure"]
      assert json_response(conn, 201)["data"]["attributes"]["customData"] == @valid_attrs["customData"]
      assert json_response(conn, 201)["data"]["relationships"]["avatar"] == %{}
      assert json_response(conn, 201)["data"]["relationships"]["externalFileCollections"] == %{}
    end

    test "with valid attrs, rels and include", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      %File{ id: avatar_id } = Repo.insert!(%File{
        account_id: account1_id,
        name: Faker.Lorem.word(),
        status: "uploaded",
        content_type: "image/png",
        size_bytes: 42
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = post(conn, "/v1/skus?include=avatar", %{
        "data" => %{
          "type" => "Sku",
          "attributes" => @valid_attrs,
          "relationships" => %{
            "avatar" => %{
              "data" => %{
                "type" => "File",
                "id" => avatar_id
              }
            }
          }
        }
      })

      assert json_response(conn, 201)["data"]["id"]
      assert json_response(conn, 201)["data"]["attributes"]["status"] == @valid_attrs["status"]
      assert json_response(conn, 201)["data"]["attributes"]["name"] == @valid_attrs["name"]
      assert json_response(conn, 201)["data"]["attributes"]["printName"] == @valid_attrs["printName"]
      assert json_response(conn, 201)["data"]["attributes"]["unitOfMeasure"] == @valid_attrs["unitOfMeasure"]
      assert json_response(conn, 201)["data"]["attributes"]["customData"] == @valid_attrs["customData"]
      assert json_response(conn, 201)["data"]["relationships"]["avatar"]["data"]["id"]
      assert length(Enum.filter(json_response(conn, 201)["included"], fn(item) -> item["type"] == "File" end)) == 1
    end
  end

  describe "GET /v1/skus/:id" do
    test "with no access token", %{ conn: conn } do
      conn = get(conn, "/v1/skus/test")

      assert conn.status == 401
    end

    test "with access token of a different account", %{ conn: conn, uat1: uat1 } do
      {:ok, %User{ default_account_id: account2_id }} = Identity.create_user(%{
        fields: %{
          "first_name" => Faker.Name.first_name(),
          "last_name" => Faker.Name.last_name(),
          "email" => "test2@example.com",
          "password" => "test1234",
          "account_name" => Faker.Company.name()
        }
      })

      sku = Repo.insert!(%Sku{
        account_id: account2_id,
        status: "active",
        name: "Orange",
        print_name: "ORANGE",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      assert_error_sent(404, fn ->
        get(conn, "/v1/skus/#{sku.id}")
      end)
    end

    test "with valid access token and id", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      sku = Repo.insert!(%Sku{
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

      conn = get(conn, "/v1/skus/#{sku.id}")

      assert json_response(conn, 200)["data"]["id"] == sku.id
      assert json_response(conn, 200)["data"]["attributes"]["name"] == "Orange"
      assert json_response(conn, 200)["data"]["attributes"]["customData"]["kind"] == "Blue Jay"
      assert json_response(conn, 200)["data"]["attributes"]["locale"] == "en"
      assert json_response(conn, 200)["data"]["relationships"]["avatar"] == %{}
    end

    test "with valid access token, id and locale", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      sku = Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Orange",
        print_name: "ORANGE",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Blue Jay"
        },
        translations: %{
          "zh-CN" => %{
            "name" => "橙子"
          }
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/skus/#{sku.id}?locale=zh-CN")

      assert json_response(conn, 200)["data"]["id"] == sku.id
      assert json_response(conn, 200)["data"]["attributes"]["name"] == "橙子"
      assert json_response(conn, 200)["data"]["attributes"]["customData"]["kind"] == "Blue Jay"
      assert json_response(conn, 200)["data"]["attributes"]["locale"] == "zh-CN"
      assert json_response(conn, 200)["data"]["relationships"]["avatar"] == %{}
    end

    test "with valid access token, id, locale and include", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      %File{ id: avatar_id } = Repo.insert!(%File{
        account_id: account1_id,
        name: Faker.Lorem.word(),
        status: "uploaded",
        content_type: "image/png",
        size_bytes: 42
      })

      sku = Repo.insert!(%Sku{
        account_id: account1_id,
        avatar_id: avatar_id,
        status: "active",
        name: "Orange",
        print_name: "ORANGE",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      Repo.insert!(%FileCollection{
        account_id: account1_id,
        sku_id: sku.id,
        label: "primary_images",
        translations: %{
          "zh-CN" => %{
            "name" => "图片"
          }
        }
      })

      Repo.insert!(%FileCollection{
        account_id: account1_id,
        sku_id: sku.id,
        label: "secondary_images",
        translations: %{
          "zh-CN" => %{
            "name" => "图片"
          }
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/skus/#{sku.id}?include=avatar,externalFileCollections&locale=zh-CN")

      assert json_response(conn, 200)["data"]["id"] == sku.id
      assert json_response(conn, 200)["data"]["attributes"]["name"] == "Orange"
      assert json_response(conn, 200)["data"]["attributes"]["customData"]["kind"] == "Blue Jay"
      assert json_response(conn, 200)["data"]["relationships"]["avatar"]["data"]["id"]
      assert length(json_response(conn, 200)["data"]["relationships"]["externalFileCollections"]["data"]) == 2
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "File" end)) == 1
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "FileCollection" end)) == 2
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["attributes"]["name"] == "图片" end)) == 2
    end
  end

  describe "PATCH /v1/skus/:id" do
    test "with no access token", %{ conn: conn } do
      conn = patch(conn, "/v1/skus/test", %{
        "data" => %{
          "id" => "test",
          "type" => "Sku",
          "attributes" => @valid_attrs
        }
      })

      assert conn.status == 401
    end

    test "with access token of a different account", %{ conn: conn, uat1: uat1 } do
      {:ok, %User{ default_account_id: account2_id }} = Identity.create_user(%{
        fields: %{
          "first_name" => Faker.Name.first_name(),
          "last_name" => Faker.Name.last_name(),
          "email" => "test2@example.com",
          "password" => "test1234",
          "account_name" => Faker.Company.name()
        }
      })

      sku = Repo.insert!(%Sku{
        account_id: account2_id,
        status: "active",
        name: "Orange",
        print_name: "ORANGE",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      assert_error_sent(404, fn ->
        patch(conn, "/v1/skus/#{sku.id}", %{
          "data" => %{
            "id" => sku.id,
            "type" => "Sku",
            "attributes" => @valid_attrs
          }
        })
      end)
    end

    test "with valid access token, invalid attrs and rels", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      sku = Repo.insert!(%Sku{
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

      conn = patch(conn, "/v1/skus/#{sku.id}", %{
        "data" => %{
          "id" => sku.id,
          "type" => "Sku",
          "attributes" => @invalid_attrs
        }
      })

      assert json_response(conn, 422)["errors"]
      assert length(json_response(conn, 422)["errors"]) > 0
    end

    test "with valid access token, attrs and rels", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      sku = Repo.insert!(%Sku{
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

      conn = patch(conn, "/v1/skus/#{sku.id}", %{
        "data" => %{
          "id" => sku.id,
          "type" => "Sku",
          "attributes" => @valid_attrs
        }
      })

      assert json_response(conn, 200)["data"]["id"] == sku.id
      assert json_response(conn, 200)["data"]["attributes"]["status"] == @valid_attrs["status"]
      assert json_response(conn, 200)["data"]["attributes"]["name"] == @valid_attrs["name"]
      assert json_response(conn, 200)["data"]["attributes"]["printName"] == @valid_attrs["printName"]
      assert json_response(conn, 200)["data"]["attributes"]["unitOfMeasure"] == @valid_attrs["unitOfMeasure"]
      assert json_response(conn, 200)["data"]["attributes"]["customData"]["kind"] == @valid_attrs["customData"]["kind"]
      assert json_response(conn, 200)["data"]["attributes"]["locale"] == "en"
    end

    test "with valid access token, attrs, rels and locale", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      sku = Repo.insert!(%Sku{
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

      conn = patch(conn, "/v1/skus/#{sku.id}?locale=zh-CN", %{
        "data" => %{
          "id" => sku.id,
          "type" => "Sku",
          "attributes" => %{
            "name" => "橙子"
          }
        }
      })

      assert json_response(conn, 200)["data"]["id"]
      assert json_response(conn, 200)["data"]["attributes"]["printName"] == "ORANGE"
      assert json_response(conn, 200)["data"]["attributes"]["name"] == "橙子"
      assert json_response(conn, 200)["data"]["attributes"]["locale"] == "zh-CN"
    end

    test "with valid access token, attrs, rels, locale and include", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      %File{ id: avatar_id } = Repo.insert!(%File{
        account_id: account1_id,
        name: Faker.Lorem.word(),
        status: "uploaded",
        content_type: "image/png",
        size_bytes: 42
      })

      sku = Repo.insert!(%Sku{
        account_id: account1_id,
        avatar_id: avatar_id,
        status: "active",
        name: "Orange",
        print_name: "ORANGE",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      Repo.insert!(%FileCollection{
        account_id: account1_id,
        sku_id: sku.id,
        label: "primary_images",
        translations: %{
          "zh-CN" => %{
            "name" => "图片"
          }
        }
      })

      Repo.insert!(%FileCollection{
        account_id: account1_id,
        sku_id: sku.id,
        label: "secondary_images",
        translations: %{
          "zh-CN" => %{
            "name" => "图片"
          }
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = patch(conn, "/v1/skus/#{sku.id}?locale=zh-CN&include=avatar,externalFileCollections", %{
        "data" => %{
          "id" => sku.id,
          "type" => "Sku",
          "attributes" => @valid_attrs
        }
      })

      assert json_response(conn, 200)["data"]["id"]
      assert json_response(conn, 200)["data"]["attributes"]["status"] == @valid_attrs["status"]
      assert json_response(conn, 200)["data"]["attributes"]["name"] == @valid_attrs["name"]
      assert json_response(conn, 200)["data"]["attributes"]["printName"] == @valid_attrs["printName"]
      assert json_response(conn, 200)["data"]["attributes"]["unitOfMeasure"] == @valid_attrs["unitOfMeasure"]
      assert json_response(conn, 200)["data"]["attributes"]["customData"]["kind"] == @valid_attrs["customData"]["kind"]
      assert json_response(conn, 200)["data"]["attributes"]["locale"] == "zh-CN"
      assert json_response(conn, 200)["data"]["relationships"]["avatar"]["data"]["id"]
      assert length(json_response(conn, 200)["data"]["relationships"]["externalFileCollections"]["data"]) == 2
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "File" end)) == 1
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "FileCollection" end)) == 2
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["attributes"]["name"] == "图片" end)) == 2
    end
  end

  describe "GET /v1/skus" do
    test "with no access token", %{ conn: conn } do
      conn = get(conn, sku_path(conn, :index))

      assert conn.status == 401
    end

    test "with valid access token", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      {:ok, %User{ default_account_id: account2_id }} = Identity.create_user(%{
        fields: %{
          "first_name" => Faker.Name.first_name(),
          "last_name" => Faker.Name.last_name(),
          "email" => "test2@example.com",
          "password" => "test1234",
          "account_name" => Faker.Company.name()
        }
      })

      Repo.insert!(%Sku{
        account_id: account2_id,
        status: "active",
        name: "Orange",
        print_name: "ORANGE",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })
      Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Orange",
        print_name: "ORANGE",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })
      Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Orange",
        print_name: "ORANGE1",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/skus")

      assert length(json_response(conn, 200)["data"]) == 2
      assert json_response(conn, 200)["meta"]["resultCount"] == 2
      assert json_response(conn, 200)["meta"]["totalCount"] == 2
    end

    test "with valid access token and pagination", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Orange",
        print_name: "ORANGE",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })
      Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Orange",
        print_name: "ORANGE1",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })
      Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Orange",
        print_name: "ORANGE2",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/skus?page[number]=2&page[size]=1")

      assert length(json_response(conn, 200)["data"]) == 1
      assert json_response(conn, 200)["meta"]["resultCount"] == 3
      assert json_response(conn, 200)["meta"]["totalCount"] == 3
    end

    test "with valid access token and filter", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      Repo.insert!(%Sku{
        account_id: account1_id,
        status: "disabled",
        name: "Orange",
        print_name: "ORANGE",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })
      Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Orange",
        print_name: "ORANGE1",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })
      Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Orange",
        print_name: "ORANGE2",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/skus?filter[status]=active")

      assert length(json_response(conn, 200)["data"]) == 2
      assert json_response(conn, 200)["meta"]["resultCount"] == 2
      assert json_response(conn, 200)["meta"]["totalCount"] == 3
    end

    test "with valid access token and locale", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Orange",
        print_name: "ORANGE",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Blue Jay"
        },
        translations: %{
          "zh-CN" => %{
            "name" => "橙子"
          }
        }
      })
      Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Orange",
        print_name: "ORANGE1",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })
      Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Orange",
        print_name: "ORANGE2",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/skus?locale=zh-CN")

      assert length(json_response(conn, 200)["data"]) == 3
      assert json_response(conn, 200)["meta"]["resultCount"] == 3
      assert json_response(conn, 200)["meta"]["totalCount"] == 3
      assert length(Enum.filter(json_response(conn, 200)["data"], fn(item) -> item["attributes"]["name"] == "橙子" end)) == 1
    end

    test "with valid access token, locale and search", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      {:ok, %User{ default_account_id: account2_id }} = Identity.create_user(%{
        fields: %{
          "first_name" => Faker.Name.first_name(),
          "last_name" => Faker.Name.last_name(),
          "email" => "test2@example.com",
          "password" => "test1234",
          "account_name" => Faker.Company.name()
        }
      })

      Repo.insert!(%Sku{
        account_id: account2_id,
        status: "active",
        name: "Orange",
        print_name: "ORANGE1",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })
      Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Apple",
        print_name: "APPLE",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })
      Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Orange",
        print_name: "ORANGE1",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Blue Jay"
        },
        translations: %{
          "zh-CN" => %{
            "name" => "橙子"
          }
        }
      })
      Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Orange",
        print_name: "ORANGE2",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Blue Jay"
        },
        translations: %{
          "zh-CN" => %{
            "name" => "橙子"
          }
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/skus?search=橙&locale=zh-CN")

      assert length(json_response(conn, 200)["data"]) == 2
      assert json_response(conn, 200)["meta"]["resultCount"] == 2
      assert json_response(conn, 200)["meta"]["totalCount"] == 3
    end

    test "with valid access token, locale and include", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      %File{ id: avatar_id } = Repo.insert!(%File{
        account_id: account1_id,
        name: Faker.Lorem.word(),
        status: "uploaded",
        content_type: "image/png",
        size_bytes: 42
      })

      Repo.insert!(%Sku{
        account_id: account1_id,
        avatar_id: avatar_id,
        status: "active",
        name: "Orange",
        print_name: "ORANGE",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      %Sku{ id: sku_id } = Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Orange",
        print_name: "ORANGE1",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      %File{ id: ef1_id } = Repo.insert!(%File{
        account_id: account1_id,
        name: Faker.Lorem.word(),
        status: "uploaded",
        content_type: "image/png",
        size_bytes: 42
      })

      %FileCollection{ id: efc1_id } = Repo.insert!(%FileCollection{
        account_id: account1_id,
        sku_id: sku_id,
        label: "primary_images",
        translations: %{
          "zh-CN" => %{
            "name" => "主要图片"
          }
        }
      })

      Repo.insert!(%FileCollectionMembership{
        account_id: account1_id,
        collection_id: efc1_id,
        file_id: ef1_id
      })

      Repo.insert!(%FileCollection{
        account_id: account1_id,
        sku_id: sku_id,
        label: "secondary_images",
        translations: %{
          "zh-CN" => %{
            "name" => "主要图片"
          }
        }
      })

      Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Orange",
        print_name: "ORANGE2",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, sku_path(conn, :index, include: "avatar,externalFileCollections.files", locale: "zh-CN"))

      assert length(json_response(conn, 200)["data"]) == 3
      assert json_response(conn, 200)["meta"]["resultCount"] == 3
      assert json_response(conn, 200)["meta"]["totalCount"] == 3
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "File" end)) == 2
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "FileCollection" end)) == 2
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["attributes"]["name"] == "主要图片" end)) == 2
    end
  end

  describe "DELETE /v1/skus/:id" do
    test "with no access token", %{ conn: conn } do
      conn = delete(conn, sku_path(conn, :delete, "test"))

      assert conn.status == 401
    end

    test "with access token of a different account", %{ conn: conn, uat1: uat1 } do
      {:ok, %User{ default_account_id: account2_id }} = Identity.create_user(%{
        fields: %{
          "first_name" => Faker.Name.first_name(),
          "last_name" => Faker.Name.last_name(),
          "email" => "test2@example.com",
          "password" => "test1234",
          "account_name" => Faker.Company.name()
        }
      })

      sku = Repo.insert!(%Sku{
        account_id: account2_id,
        status: "active",
        name: "Orange",
        print_name: "ORANGE",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      assert_error_sent(404, fn ->
        delete(conn, sku_path(conn, :delete, sku.id))
      end)
    end

    test "with valid access token and id", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      sku = Repo.insert!(%Sku{
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

      conn = delete(conn, sku_path(conn, :delete, sku.id))

      assert conn.status == 204
    end
  end
end
