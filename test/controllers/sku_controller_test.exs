defmodule BlueJet.SkuControllerTest do
  use BlueJet.ConnCase

  alias BlueJet.User
  alias BlueJet.UserRegistration
  alias BlueJet.Authentication

  alias BlueJet.Sku
  alias BlueJet.ExternalFile
  alias BlueJet.ExternalFileCollection
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

  describe "POST /v1/skus" do
    test "with no access token", %{ conn: conn } do
      conn = post(conn, sku_path(conn, :create), %{
        "data" => %{
          "type" => "Sku",
          "attributes" => @valid_attrs
        }
      })

      assert conn.status == 401
    end

    test "with invalid attrs", %{ conn: conn, uat1: uat1 } do
      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = post(conn, sku_path(conn, :create), %{
        "data" => %{
          "type" => "Sku",
          "attributes" => @invalid_attrs
        }
      })

      assert json_response(conn, 422)["errors"]
      assert length(json_response(conn, 422)["errors"]) > 0
    end

    test "with valid attrs", %{ conn: conn, uat1: uat1 } do
      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = post(conn, sku_path(conn, :create), %{
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

    test "with valid attrs and include", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      %ExternalFile{ id: avatar_id } = Repo.insert!(%ExternalFile{
        account_id: account1_id,
        name: Faker.Lorem.word(),
        status: "uploaded",
        content_type: "image/png",
        size_bytes: 42
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = post(conn, sku_path(conn, :create, include: "avatar"), %{
        "data" => %{
          "type" => "Sku",
          "attributes" => @valid_attrs,
          "relationships" => %{
            "avatar" => %{
              "data" => %{
                "type" => "ExternalFile",
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
      assert length(Enum.filter(json_response(conn, 201)["included"], fn(item) -> item["type"] == "ExternalFile" end)) == 1
    end
  end

  describe "GET /v1/skus/:id" do
    test "with no access token", %{ conn: conn } do
      conn = get(conn, sku_path(conn, :show, "test"))

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
        get(conn, sku_path(conn, :show, sku.id))
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

      conn = get(conn, sku_path(conn, :show, sku.id))

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

      conn = get(conn, sku_path(conn, :show, sku.id, locale: "zh-CN"))

      assert json_response(conn, 200)["data"]["id"] == sku.id
      assert json_response(conn, 200)["data"]["attributes"]["name"] == "橙子"
      assert json_response(conn, 200)["data"]["attributes"]["customData"]["kind"] == "Blue Jay"
      assert json_response(conn, 200)["data"]["attributes"]["locale"] == "zh-CN"
      assert json_response(conn, 200)["data"]["relationships"]["avatar"] == %{}
    end

    test "with valid access token, id and include", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      %ExternalFile{ id: avatar_id } = Repo.insert!(%ExternalFile{
        account_id: account1_id,
        name: Faker.Lorem.word(),
        status: "uploaded",
        content_type: "image/png",
        size_bytes: 42
      })

      %Sku{ id: sku_id } = Repo.insert!(%Sku{
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

      Repo.insert!(%ExternalFileCollection{
        account_id: account1_id,
        sku_id: sku_id,
        label: "primary_images"
      })

      Repo.insert!(%ExternalFileCollection{
        account_id: account1_id,
        sku_id: sku_id,
        label: "secondary_images"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, sku_path(conn, :show, sku_id, include: "avatar,externalFileCollections"))

      assert json_response(conn, 200)["data"]["id"] == sku_id
      assert json_response(conn, 200)["data"]["attributes"]["name"] == "Orange"
      assert json_response(conn, 200)["data"]["attributes"]["customData"]["kind"] == "Blue Jay"
      assert json_response(conn, 200)["data"]["relationships"]["avatar"]["data"]["id"]
      assert length(json_response(conn, 200)["data"]["relationships"]["externalFileCollections"]["data"]) == 2
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "ExternalFile" end)) == 1
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "ExternalFileCollection" end)) == 2
    end
  end

  describe "PATCH /v1/skus/:id" do
    test "with no access token", %{ conn: conn } do
      conn = patch(conn, sku_path(conn, :update, "test"), %{
        "data" => %{
          "id" => "test",
          "type" => "Sku",
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
        patch(conn, sku_path(conn, :update, sku.id), %{
          "data" => %{
            "id" => sku.id,
            "type" => "Sku",
            "attributes" => @valid_attrs
          }
        })
      end)
    end

    test "with good access token but invalid attrs", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
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

      conn = patch(conn, sku_path(conn, :update, sku.id), %{
        "data" => %{
          "id" => sku.id,
          "type" => "Sku",
          "attributes" => @invalid_attrs
        }
      })

      assert json_response(conn, 422)["errors"]
      assert length(json_response(conn, 422)["errors"]) > 0
    end

    test "with good access token and valid attrs", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
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

      conn = patch(conn, sku_path(conn, :update, sku_id), %{
        "data" => %{
          "id" => sku_id,
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
      assert json_response(conn, 200)["data"]["attributes"]["locale"] == "en"
    end

    test "with good access token, valid attrs and locale", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
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

      conn = patch(conn, sku_path(conn, :update, sku_id, locale: "zh-CN"), %{
        "data" => %{
          "id" => sku_id,
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

    test "with good access token, valid attrs and include", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      %ExternalFile{ id: avatar_id } = Repo.insert!(%ExternalFile{
        account_id: account1_id,
        name: Faker.Lorem.word(),
        status: "uploaded",
        content_type: "image/png",
        size_bytes: 42
      })

      %Sku{ id: sku_id } = Repo.insert!(%Sku{
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

      Repo.insert!(%ExternalFileCollection{
        account_id: account1_id,
        sku_id: sku_id,
        label: "primary_images"
      })

      Repo.insert!(%ExternalFileCollection{
        account_id: account1_id,
        sku_id: sku_id,
        label: "secondary_images"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = patch(conn, sku_path(conn, :update, sku_id, include: "avatar,externalFileCollections"), %{
        "data" => %{
          "id" => sku_id,
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
      assert json_response(conn, 200)["data"]["attributes"]["locale"] == "en"
      assert json_response(conn, 200)["data"]["relationships"]["avatar"]["data"]["id"]
      assert length(json_response(conn, 200)["data"]["relationships"]["externalFileCollections"]["data"]) == 2
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "ExternalFile" end)) == 1
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "ExternalFileCollection" end)) == 2
    end
  end

  describe "GET /v1/skus" do
    test "with no access token", %{ conn: conn } do
      conn = get(conn, sku_path(conn, :index))

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

      conn = get(conn, sku_path(conn, :index))

      assert length(json_response(conn, 200)["data"]) == 2
    end

    test "with good access token and locale", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
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

      conn = get(conn, sku_path(conn, :index, locale: "zh-CN"))

      assert length(json_response(conn, 200)["data"]) == 3
      assert length(Enum.filter(json_response(conn, 200)["data"], fn(item) -> item["attributes"]["name"] == "橙子" end)) == 1
    end

    test "with good access token and pagination", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
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

      conn = get(conn, sku_path(conn, :index, %{ "page[number]" => 2, "page[size]" => 1 }))

      assert length(json_response(conn, 200)["data"]) == 1
    end

    test "with good access token and search", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
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

      conn = get(conn, sku_path(conn, :index, search: "oran"))

      assert length(json_response(conn, 200)["data"]) == 2
    end
  end

  describe "DELETE /v1/skus/:id" do
    test "with no access token", %{ conn: conn } do
      conn = delete(conn, sku_path(conn, :delete, "test"))

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
