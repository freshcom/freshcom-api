defmodule BlueJetWeb.ProductItemControllerTest do
  use BlueJetWeb.ConnCase

  alias BlueJet.Identity.User

  alias BlueJet.Storefront.Product
  alias BlueJet.Inventory.Sku
  alias BlueJet.Storefront.ProductItem
  alias BlueJet.Repo

  @valid_attrs %{
    "status" => "active",
    "customData" => %{
      "kind" => "Gala"
    }
  }
  @invalid_attrs %{
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

  describe "POST /v1/products/:id/items" do
    test "with no access token", %{ conn: conn } do
      conn = post(conn, "/v1/products/#{Ecto.UUID.generate()}/items", %{
        "data" => %{
          "type" => "ProductItem",
          "attributes" => @valid_attrs
        }
      })

      assert conn.status == 401
    end

    test "with invalid attrs and rels", %{ conn: conn, uat1: uat1 } do
      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = post(conn, "/v1/products/#{Ecto.UUID.generate()}/items", %{
        "data" => %{
          "type" => "ProductItem",
          "attributes" => @invalid_attrs
        }
      })

      assert json_response(conn, 422)["errors"]
      assert length(json_response(conn, 422)["errors"]) > 0
    end

    test "with valid attrs and rels", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      %Product{ id: product_id } = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple"
      })

      %Sku{ id: sku_id } = Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Apple",
        print_name: "APPLE",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Gala"
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = post(conn, "/v1/products/#{product_id}/items", %{
        "data" => %{
          "type" => "ProductItem",
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
      assert json_response(conn, 201)["data"]["attributes"]["status"] == @valid_attrs["status"]
      assert json_response(conn, 201)["data"]["attributes"]["customData"] == @valid_attrs["customData"]
    end

    test "with valid attrs, rels and include", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      %Product{ id: product_id } = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple"
      })

      %Sku{ id: sku_id } = Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Apple",
        print_name: "APPLE",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Gala"
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = post(conn, "/v1/products/#{product_id}/items?include=product,sku", %{
        "data" => %{
          "type" => "ProductItem",
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
      assert json_response(conn, 201)["data"]["attributes"]["status"] == @valid_attrs["status"]
      assert json_response(conn, 201)["data"]["attributes"]["customData"] == @valid_attrs["customData"]
      assert length(Enum.filter(json_response(conn, 201)["included"], fn(item) -> item["type"] == "Product" end)) == 1
      assert length(Enum.filter(json_response(conn, 201)["included"], fn(item) -> item["type"] == "Sku" end)) == 1
    end
  end

  describe "GET /v1/product_items/:id" do
    test "with no access token", %{ conn: conn } do
      conn = get(conn, "/v1/product_items/test")

      assert conn.status == 401
    end

    test "with with access token of a different account", %{ conn: conn, uat1: uat1 } do
      {:ok, %User{ default_account_id: account2_id }} = Identity.create_user(%{
        fields: %{
          "first_name" => Faker.Name.first_name(),
          "last_name" => Faker.Name.last_name(),
          "email" => "test2@example.com",
          "password" => "test1234",
          "account_name" => Faker.Company.name()
        }
      })

      %Product{ id: product_id } = Repo.insert!(%Product{
        account_id: account2_id,
        status: "active",
        name: "Apple"
      })

      %Sku{ id: sku_id } = Repo.insert!(%Sku{
        account_id: account2_id,
        status: "active",
        name: "Apple",
        print_name: "APPLE",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Gala"
        }
      })

      product_item = Repo.insert!(%ProductItem{
        account_id: account2_id,
        product_id: product_id,
        sku_id: sku_id,
        status: "active",
        name: "Apple",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      assert_error_sent(404, fn ->
        get(conn, "/v1/product_items/#{product_item.id}")
      end)
    end

    test "with valid access token and id", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      %Product{ id: product_id } = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple"
      })

      %Sku{ id: sku_id } = Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Apple",
        print_name: "APPLE",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Gala"
        }
      })

      product_item = Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product_id,
        sku_id: sku_id,
        status: "active",
        name: "Apple",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/product_items/#{product_item.id}")

      assert json_response(conn, 200)["data"]["id"] == product_item.id
      assert json_response(conn, 200)["data"]["attributes"]["status"] == @valid_attrs["status"]
    end

    test "with valid access token, id and locale", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      %Product{ id: product_id } = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple"
      })

      %Sku{ id: sku_id } = Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Apple",
        print_name: "APPLE",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Gala"
        }
      })

      product_item = Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product_id,
        sku_id: sku_id,
        status: "active",
        name: "Apple",
        custom_data: %{
          "kind" => "Blue Jay"
        },
        translations: %{
          "zh-CN" => %{
            "short_name" => "橙子"
          }
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/product_items/#{product_item.id}?locale=zh-CN")

      assert json_response(conn, 200)["data"]["id"] == product_item.id
      assert json_response(conn, 200)["data"]["attributes"]["status"] == @valid_attrs["status"]
      assert json_response(conn, 200)["data"]["attributes"]["shortName"] == "橙子"
      assert json_response(conn, 200)["data"]["attributes"]["locale"] == "zh-CN"
    end

    test "with valid access token, id, locale and include", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      %Product{ id: product_id } = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple"
      })

      %Sku{ id: sku_id } = Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Apple",
        print_name: "APPLE",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Gala"
        },
        translations: %{
          "zh-CN" => %{
            "name" => "苹果"
          }
        }
      })

      product_item = Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product_id,
        sku_id: sku_id,
        status: "active",
        name: "Apple",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/product_items/#{product_item.id}?include=sku,product&locale=zh-CN")

      assert json_response(conn, 200)["data"]["id"] == product_item.id
      assert json_response(conn, 200)["data"]["attributes"]["status"] == @valid_attrs["status"]
      assert json_response(conn, 200)["data"]["relationships"]["sku"]["data"]["id"] == sku_id
      assert json_response(conn, 200)["data"]["relationships"]["product"]["data"]["id"] == product_id
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "Product" end)) == 1
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "Sku" end)) == 1
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["attributes"]["name"] == "苹果" end)) == 1
    end
  end

  describe "PATCH /v1/product_items/:id" do
    test "with no access token", %{ conn: conn } do
      conn = patch(conn, "/v1/product_items/test", %{
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

      %Product{ id: product_id } = Repo.insert!(%Product{
        account_id: account2_id,
        status: "active",
        name: "Apple"
      })

      %Sku{ id: sku_id } = Repo.insert!(%Sku{
        account_id: account2_id,
        status: "active",
        name: "Apple",
        print_name: "APPLE",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Gala"
        }
      })

      product_item = Repo.insert!(%ProductItem{
        account_id: account2_id,
        product_id: product_id,
        sku_id: sku_id,
        status: "active",
        name: "Apple",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      assert_error_sent(404, fn ->
        patch(conn, "/v1/product_items/#{product_item.id}", %{
          "data" => %{
            "id" => product_item.id,
            "type" => "ProductItem",
            "attributes" => @valid_attrs
          }
        })
      end)
    end

    test "with valid access token, invalid attrs and rels", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      %Product{ id: product_id } = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple"
      })

      product_item = Repo.insert!(%ProductItem{
        product_id: product_id,
        account_id: account1_id,
        status: "active",
        name: "Apple",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = patch(conn, "/v1/product_items/#{product_item.id}", %{
        "data" => %{
          "id" => product_item.id,
          "type" => "ProductItem",
          "attributes" => @invalid_attrs
        }
      })

      assert json_response(conn, 422)["errors"]
      assert length(json_response(conn, 422)["errors"]) > 0
    end

    test "with valid access token, attrs and rels", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      %Product{ id: product_id } = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple"
      })

      %Sku{ id: sku_id } = Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Apple",
        print_name: "APPLE",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Gala"
        }
      })

      product_item = Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product_id,
        sku_id: sku_id,
        status: "active",
        name: "Apple",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = patch(conn, "/v1/product_items/#{product_item.id}", %{
        "data" => %{
          "id" => product_item.id,
          "type" => "ProductItem",
          "attributes" => @valid_attrs
        }
      })

      assert json_response(conn, 200)["data"]["id"]
      assert json_response(conn, 200)["data"]["attributes"]["status"] == @valid_attrs["status"]
      assert json_response(conn, 200)["data"]["attributes"]["customData"] == @valid_attrs["customData"]
    end

    test "with valid access token, attrs, rels and locale", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      %Product{ id: product_id } = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple"
      })

      %Sku{ id: sku_id } = Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Apple",
        print_name: "APPLE",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Gala"
        }
      })

      product_item = Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product_id,
        sku_id: sku_id,
        status: "active",
        name: "Apple",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = patch(conn, "/v1/product_items/#{product_item.id}?locale=zh-CN", %{
        "data" => %{
          "id" => product_item.id,
          "type" => "ProductItem",
          "attributes" => %{
            "shortName" => "橙子"
          }
        }
      })

      assert json_response(conn, 200)["data"]["id"]
      assert json_response(conn, 200)["data"]["attributes"]["shortName"] == "橙子"
      assert json_response(conn, 200)["data"]["attributes"]["locale"] == "zh-CN"
    end

    test "with valid access token, attrs, rels, locale and include", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      %Product{ id: product_id } = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple"
      })

      %Sku{ id: sku_id } = Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Apple",
        print_name: "APPLE",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Gala"
        },
        translations: %{
          "zh-CN" => %{
            "name" => "苹果"
          }
        }
      })

      product_item = Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product_id,
        sku_id: sku_id,
        status: "active",
        name: "Apple",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = patch(conn, "/v1/product_items/#{product_item.id}?locale=zh-CN&include=product,sku", %{
        "data" => %{
          "id" => product_item.id,
          "type" => "ProductItem",
          "attributes" => %{
            "shortName" => "橙子"
          }
        }
      })

      assert json_response(conn, 200)["data"]["id"]
      assert json_response(conn, 200)["data"]["attributes"]["shortName"] == "橙子"
      assert json_response(conn, 200)["data"]["attributes"]["locale"] == "zh-CN"
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "Product" end)) == 1
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "Sku" end)) == 1
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["attributes"]["name"] == "苹果" end)) == 1
    end
  end

  describe "GET /v1/product_items" do
    test "with no access token", %{ conn: conn } do
      conn = get(conn, "/v1/product_items")

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

      %Product{ id: product_id } = Repo.insert!(%Product{
        account_id: account2_id,
        status: "active",
        name: "Apple"
      })
      %Sku{ id: sku_id } = Repo.insert!(%Sku{
        account_id: account2_id,
        status: "active",
        name: "Apple",
        print_name: "APPLE",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Gala"
        }
      })
      Repo.insert!(%ProductItem{
        account_id: account2_id,
        product_id: product_id,
        sku_id: sku_id,
        status: "active",
        name: "Apple",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      %Product{ id: product_id } = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple"
      })
      %Sku{ id: sku_id } = Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Apple",
        print_name: "APPLE1",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Gala"
        }
      })
      Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product_id,
        sku_id: sku_id,
        status: "active",
        name: "Apple",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      %Product{ id: product_id } = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple"
      })
      %Sku{ id: sku_id } = Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Apple",
        print_name: "APPLE",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Gala"
        }
      })
      Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product_id,
        sku_id: sku_id,
        status: "active",
        name: "Apple",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/product_items")

      assert length(json_response(conn, 200)["data"]) == 2
    end

    test "with valid access token and pagination", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      %Product{ id: product1_id } = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple"
      })
      %Sku{ id: sku1_id } = Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Good Apple",
        print_name: "APPLE1",
        unit_of_measure: "EA"
      })
      Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product1_id,
        sku_id: sku1_id,
        short_name: "Fuji",
        name: "Fuji",
        status: "active"
      })

      %Product{ id: product2_id } = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Another Apple"
      })
      Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product2_id,
        sku_id: sku1_id,
        short_name: "Gala",
        name: "Gala",
        status: "active"
      })

      %Product{ id: product3_id } = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple"
      })
      %Sku{ id: sku2_id } = Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Good Apple",
        print_name: "APPLE2",
        unit_of_measure: "EA"
      })
      Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product3_id,
        sku_id: sku2_id,
        short_name: "Fuji",
        name: "Fuji",
        status: "active"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/product_items?page[number]=2&page[size]=1")

      assert length(json_response(conn, 200)["data"]) == 1
      assert json_response(conn, 200)["meta"]["resultCount"] == 3
      assert json_response(conn, 200)["meta"]["totalCount"] == 3
    end

    test "with valid access token and filter", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      %Product{ id: product1_id } = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple"
      })
      %Sku{ id: sku1_id } = Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Good Apple",
        print_name: "APPLE1",
        unit_of_measure: "EA"
      })
      Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product1_id,
        sku_id: sku1_id,
        name: "Fuji",
        short_name: "Fuji",
        status: "active"
      })

      %Product{ id: product2_id } = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Another Apple"
      })
      Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product2_id,
        sku_id: sku1_id,
        name: "Gala",
        short_name: "Gala",
        status: "active"
      })

      %Product{ id: product3_id } = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple"
      })
      %Sku{ id: sku2_id } = Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Good Apple",
        print_name: "APPLE2",
        unit_of_measure: "EA"
      })
      Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product3_id,
        sku_id: sku2_id,
        name: "Fuji",
        short_name: "Fuji",
        status: "active"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/product_items?filter[skuId]=#{sku1_id}")

      assert length(json_response(conn, 200)["data"]) == 2
      assert json_response(conn, 200)["meta"]["resultCount"] == 2
      assert json_response(conn, 200)["meta"]["totalCount"] == 3
    end

    test "with valid access token and locale", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      %Product{ id: product1_id } = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple",
        translations: %{
          "zh-CN" => %{
            "name" => "苹果"
          }
        }
      })
      %Sku{ id: sku1_id } = Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Good Apple",
        print_name: "APPLE1",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Gala"
        },
        translations: %{
          "zh-CN" => %{
            "name" => "好的苹果"
          }
        }
      })
      Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product1_id,
        sku_id: sku1_id,
        short_name: "Fuji",
        name: "Fuji",
        status: "active",
        custom_data: %{
          "kind" => "Blue Jay"
        },
        translations: %{
          "zh-CN" => %{
            "short_name" => "红富士"
          }
        }
      })

      %Product{ id: product2_id } = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Another Apple",
        translations: %{
          "zh-CN" => %{
            "name" => "又一个苹果"
          }
        }
      })
      Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product2_id,
        sku_id: sku1_id,
        name: "Gala",
        short_name: "Gala",
        status: "active",
        custom_data: %{
          "kind" => "Blue Jay"
        },
        translations: %{
          "zh-CN" => %{
            "short_name" => "红富士"
          }
        }
      })

      %Product{ id: product3_id } = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple",
        translations: %{
          "zh-CN" => %{
            "name" => "苹果"
          }
        }
      })
      %Sku{ id: sku2_id } = Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Good Apple",
        print_name: "APPLE2",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Gala"
        }
      })
      Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product3_id,
        sku_id: sku2_id,
        name: "Fuji",
        short_name: "Fuji",
        status: "active",
        custom_data: %{
          "kind" => "Blue Jay"
        },
        translations: %{
          "zh-CN" => %{
            "short_name" => "红富士"
          }
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/product_items?locale=zh-CN")

      assert length(json_response(conn, 200)["data"]) == 3
      assert length(Enum.filter(json_response(conn, 200)["data"], fn(item) -> item["attributes"]["shortName"] == "红富士" end)) == 3
    end

    test "with valid access token, locale and search", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      %Product{ id: product1_id } = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple",
        translations: %{
          "zh-CN" => %{
            "name" => "苹果"
          }
        }
      })
      %Sku{ id: sku1_id } = Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Good Apple",
        print_name: "APPLE1",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Gala"
        },
        translations: %{
          "zh-CN" => %{
            "name" => "好的苹果"
          }
        }
      })
      Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product1_id,
        sku_id: sku1_id,
        name: "Fuji",
        short_name: "Fuji",
        status: "active",
        custom_data: %{
          "kind" => "Blue Jay"
        },
        translations: %{
          "zh-CN" => %{
            "short_name" => "红富士"
          }
        }
      })

      %Product{ id: product2_id } = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Another Apple",
        translations: %{
          "zh-CN" => %{
            "name" => "又一个苹果"
          }
        }
      })
      Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product2_id,
        sku_id: sku1_id,
        name: "Gala",
        short_name: "Gala",
        status: "active",
        custom_data: %{
          "kind" => "Blue Jay"
        },
        translations: %{
          "zh-CN" => %{
            "short_name" => "基那"
          }
        }
      })

      %Product{ id: product3_id } = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple",
        translations: %{
          "zh-CN" => %{
            "name" => "苹果"
          }
        }
      })
      %Sku{ id: sku2_id } = Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Good Apple",
        print_name: "APPLE2",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Gala"
        }
      })
      Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product3_id,
        sku_id: sku2_id,
        name: "Fuji",
        short_name: "Fuji",
        status: "active",
        custom_data: %{
          "kind" => "Blue Jay"
        },
        translations: %{
          "zh-CN" => %{
            "short_name" => "红富士"
          }
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/product_items?locale=zh-CN&search=红")

      assert length(json_response(conn, 200)["data"]) == 2
      assert json_response(conn, 200)["meta"]["resultCount"] == 2
      assert json_response(conn, 200)["meta"]["totalCount"] == 3
    end

    test "with valid access token, locale and include", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      %Product{ id: product1_id } = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple",
        translations: %{
          "zh-CN" => %{
            "name" => "苹果"
          }
        }
      })
      %Sku{ id: sku1_id } = Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Good Apple",
        print_name: "APPLE1",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Gala"
        },
        translations: %{
          "zh-CN" => %{
            "name" => "好的苹果"
          }
        }
      })
      Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product1_id,
        sku_id: sku1_id,
        name: "Fuji",
        short_name: "Fuji",
        status: "active",
        custom_data: %{
          "kind" => "Blue Jay"
        },
        translations: %{
          "zh-CN" => %{
            "short_name" => "红富士"
          }
        }
      })

      %Product{ id: product2_id } = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Another Apple",
        translations: %{
          "zh-CN" => %{
            "name" => "又一个苹果"
          }
        }
      })
      Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product2_id,
        sku_id: sku1_id,
        name: "Gala",
        short_name: "Gala",
        status: "active",
        custom_data: %{
          "kind" => "Blue Jay"
        },
        translations: %{
          "zh-CN" => %{
            "short_name" => "基那"
          }
        }
      })

      %Product{ id: product3_id } = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple",
        translations: %{
          "zh-CN" => %{
            "name" => "苹果"
          }
        }
      })
      %Sku{ id: sku2_id } = Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Good Apple",
        print_name: "APPLE2",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Gala"
        }
      })
      Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product3_id,
        sku_id: sku2_id,
        name: "Fuji",
        short_name: "Fuji",
        status: "active",
        custom_data: %{
          "kind" => "Blue Jay"
        },
        translations: %{
          "zh-CN" => %{
            "short_name" => "红富士"
          }
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/product_items?locale=zh-CN&include=sku,product")

      assert length(json_response(conn, 200)["data"]) == 3
      assert json_response(conn, 200)["meta"]["resultCount"] == 3
      assert json_response(conn, 200)["meta"]["totalCount"] == 3
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "Product" end)) == 3
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "Sku" end)) == 2
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["attributes"]["name"] == "苹果" end)) == 2
    end
  end

  describe "DELETE /v1/product_items/:id" do
    test "with no access token", %{ conn: conn } do
      conn = delete(conn, "/v1/product_items/test")

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

      %Product{ id: product_id } = Repo.insert!(%Product{
        account_id: account2_id,
        status: "active",
        name: "Apple"
      })

      %Sku{ id: sku_id } = Repo.insert!(%Sku{
        account_id: account2_id,
        status: "active",
        name: "Apple",
        print_name: "APPLE",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Gala"
        }
      })

      product_item = Repo.insert!(%ProductItem{
        account_id: account2_id,
        product_id: product_id,
        sku_id: sku_id,
        status: "active",
        name: "Blue Jay",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      assert_error_sent(404, fn ->
        delete(conn, "/v1/product_items/#{product_item.id}")
      end)
    end

    test "with valid access token and id", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      %Product{ id: product_id } = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple"
      })

      %Sku{ id: sku_id } = Repo.insert!(%Sku{
        account_id: account1_id,
        status: "active",
        name: "Apple",
        print_name: "APPLE",
        unit_of_measure: "EA",
        custom_data: %{
          "kind" => "Gala"
        }
      })

      product_item = Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product_id,
        sku_id: sku_id,
        status: "active",
        name: "Gala",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = delete(conn, "/v1/product_items/#{product_item.id}")

      assert conn.status == 204
    end
  end
end
