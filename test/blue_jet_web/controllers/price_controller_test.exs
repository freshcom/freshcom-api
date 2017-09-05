defmodule BlueJetWeb.PriceControllerTest do
  use BlueJetWeb.ConnCase

  alias BlueJet.Identity.User

  alias BlueJet.Storefront.Price
  alias BlueJet.Storefront.ProductItem
  alias BlueJet.Storefront.Product
  alias BlueJet.Inventory.Unlockable
  alias BlueJet.Repo

  @valid_attrs %{
    "status" => "active",
    "label" => "regular",
    "chargeCents" => 1500,
    "orderUnit" => "EA",
    "chargeUnit" => "EA",
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

    %Unlockable{ id: unlockable_id } = Repo.insert!(%Unlockable{
      account_id: account1_id,
      status: "active",
      name: "Orange",
      print_name: "ORANGE"
    })

    %Product{ id: product_id } = Repo.insert!(%Product{
      account_id: account1_id,
      status: "active",
      name: "Apple"
    })

    %ProductItem{ id: pi1_id } = Repo.insert!(%ProductItem{
      account_id: account1_id,
      product_id: product_id,
      unlockable_id: unlockable_id,
      status: "active",
      name: "Apple"
    })

    conn = build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{ conn: conn, uat1: uat1, account1_id: account1_id, pi1_id: pi1_id }
  end

  describe "POST /v1/product_items/:id/prices" do
    test "with no access token", %{ conn: conn, pi1_id: pi1_id } do
      conn = post(conn, "/v1/product_items/#{pi1_id}/prices", %{
        "data" => %{
          "type" => "Price",
          "attributes" => @valid_attrs
        }
      })

      assert conn.status == 401
    end

    test "with invalid attrs and rels", %{ conn: conn, uat1: uat1, pi1_id: pi1_id } do
      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = post(conn, "/v1/product_items/#{pi1_id}/prices", %{
        "data" => %{
          "type" => "Price",
          "attributes" => @invalid_attrs
        }
      })

      assert json_response(conn, 422)["errors"]
      assert length(json_response(conn, 422)["errors"]) > 0
    end

    test "with valid attrs and rels", %{ conn: conn, uat1: uat1, pi1_id: pi1_id } do
      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = post(conn, "/v1/product_items/#{pi1_id}/prices", %{
        "data" => %{
          "type" => "Price",
          "attributes" => @valid_attrs
        }
      })

      assert json_response(conn, 201)["data"]["id"]
      assert json_response(conn, 201)["data"]["attributes"]["status"] == @valid_attrs["status"]
      assert json_response(conn, 201)["data"]["attributes"]["label"] == @valid_attrs["label"]
      assert json_response(conn, 201)["data"]["attributes"]["chargeCents"] == @valid_attrs["chargeCents"]
      assert json_response(conn, 201)["data"]["attributes"]["orderUnit"] == @valid_attrs["orderUnit"]
      assert json_response(conn, 201)["data"]["attributes"]["chargeUnit"] == @valid_attrs["chargeUnit"]
      assert json_response(conn, 201)["data"]["attributes"]["customData"] == @valid_attrs["customData"]
    end

    test "with valid attrs, rels and include", %{ conn: conn, uat1: uat1, pi1_id: pi1_id } do
      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = post(conn, "/v1/product_items/#{pi1_id}/prices?include=productItem", %{
        "data" => %{
          "type" => "Price",
          "attributes" => @valid_attrs
        }
      })

      assert json_response(conn, 201)["data"]["id"]
      assert json_response(conn, 201)["data"]["attributes"]["status"] == @valid_attrs["status"]
      assert json_response(conn, 201)["data"]["attributes"]["label"] == @valid_attrs["label"]
      assert json_response(conn, 201)["data"]["attributes"]["chargeCents"] == @valid_attrs["chargeCents"]
      assert json_response(conn, 201)["data"]["attributes"]["orderUnit"] == @valid_attrs["orderUnit"]
      assert json_response(conn, 201)["data"]["attributes"]["chargeUnit"] == @valid_attrs["chargeUnit"]
      assert json_response(conn, 201)["data"]["attributes"]["customData"] == @valid_attrs["customData"]
      assert length(Enum.filter(json_response(conn, 201)["included"], fn(item) -> item["type"] == "ProductItem" end)) == 1
    end
  end

  describe "GET /v1/prices/:id" do
    test "with no access token", %{ conn: conn } do
      conn = get(conn, "/v1/prices/test")

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

      product = Repo.insert!(%Product{
        account_id: account2_id,
        status: "active",
        name: "Apple"
      })

      product_item = Repo.insert!(%ProductItem{
        account_id: account2_id,
        product_id: product.id,
        status: "active",
        name: "Apple"
      })

      price = Repo.insert!(%Price{
        account_id: account2_id,
        product_item_id: product_item.id,
        status: "active",
        label: "regular",
        charge_cents: 1500,
        order_unit: "EA",
        charge_unit: "EA"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      assert_error_sent(404, fn ->
        get(conn, "/v1/prices/#{price.id}")
      end)
    end

    test "with valid access token and id", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      product = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple"
      })

      product_item = Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product.id,
        status: "active",
        name: "Apple"
      })

      price = Repo.insert!(%Price{
        account_id: account1_id,
        product_item_id: product_item.id,
        status: "active",
        label: "regular",
        charge_cents: 1500,
        order_unit: "EA",
        charge_unit: "EA"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/prices/#{price.id}")

      assert json_response(conn, 200)["data"]["id"] == price.id
      assert json_response(conn, 200)["data"]["attributes"]["status"] == "active"
      assert json_response(conn, 200)["data"]["attributes"]["label"] == "regular"
    end

    test "with valid access token, id and locale", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      product = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple"
      })

      product_item = Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product.id,
        status: "active",
        name: "Apple"
      })

      price = Repo.insert!(%Price{
        account_id: account1_id,
        product_item_id: product_item.id,
        status: "active",
        label: "regular",
        charge_cents: 1500,
        order_unit: "EA",
        charge_unit: "EA",
        translations: %{
          "zh-CN" => %{
            "name" => "原价"
          }
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/prices/#{price.id}?locale=zh-CN")

      assert json_response(conn, 200)["data"]["id"] == price.id
      assert json_response(conn, 200)["data"]["attributes"]["status"] == "active"
      assert json_response(conn, 200)["data"]["attributes"]["label"] == "regular"
      assert json_response(conn, 200)["data"]["attributes"]["name"] == "原价"
    end

    test "with valid access token, id, locale and include", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      product = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple",
        translations: %{
          "zh-CN" => %{
            "name" => "苹果"
          }
        }
      })

      product_item = Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product.id,
        status: "active",
        name: "Apple"
      })

      price = Repo.insert!(%Price{
        account_id: account1_id,
        product_item_id: product_item.id,
        status: "active",
        label: "regular",
        charge_cents: 1500,
        order_unit: "EA",
        charge_unit: "EA",
        translations: %{
          "zh-CN" => %{
            "name" => "原价"
          }
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/prices/#{price.id}?locale=zh-CN&include=productItem.product")

      assert json_response(conn, 200)["data"]["id"] == price.id
      assert json_response(conn, 200)["data"]["attributes"]["status"] == "active"
      assert json_response(conn, 200)["data"]["attributes"]["label"] == "regular"
      assert json_response(conn, 200)["data"]["attributes"]["name"] == "原价"
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "Product" end)) == 1
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "ProductItem" end)) == 1
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["attributes"]["name"] == "苹果" end)) == 1
    end
  end

  describe "PATCH /v1/prices/:id" do
    test "with no access token", %{ conn: conn } do
      conn = patch(conn, "/v1/prices/test", %{
        "data" => %{
          "id" => "test",
          "type" => "Price",
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

      product = Repo.insert!(%Product{
        account_id: account2_id,
        status: "active",
        name: "Apple",
        translations: %{
          "zh-CN" => %{
            "name" => "苹果"
          }
        }
      })

      product_item = Repo.insert!(%ProductItem{
        account_id: account2_id,
        product_id: product.id,
        status: "active",
        name: "Apple"
      })

      price = Repo.insert!(%Price{
        account_id: account2_id,
        product_item_id: product_item.id,
        status: "active",
        label: "regular",
        charge_cents: 1500,
        order_unit: "EA",
        charge_unit: "EA",
        translations: %{
          "zh-CN" => %{
            "name" => "原价"
          }
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      assert_error_sent(404, fn ->
        patch(conn, "/v1/prices/#{price.id}", %{
          "data" => %{
            "id" => price.id,
            "type" => "Price",
            "attributes" => @valid_attrs
          }
        })
      end)
    end

    test "with valid access token, invalid attrs and rels", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      product = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple",
        translations: %{
          "zh-CN" => %{
            "name" => "苹果"
          }
        }
      })

      product_item = Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product.id,
        status: "active",
        name: "Apple"
      })

      price = Repo.insert!(%Price{
        account_id: account1_id,
        product_item_id: product_item.id,
        status: "active",
        label: "regular",
        charge_cents: 1500,
        order_unit: "EA",
        charge_unit: "EA",
        translations: %{
          "zh-CN" => %{
            "name" => "原价"
          }
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = patch(conn, "/v1/prices/#{price.id}", %{
        "data" => %{
          "id" => price.id,
          "type" => "Price",
          "attributes" => %{
            "label" => ""
          }
        }
      })

      assert json_response(conn, 422)["errors"]
      assert length(json_response(conn, 422)["errors"]) > 0
    end

    test "with valid access token, attrs and rels", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      product = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple",
        translations: %{
          "zh-CN" => %{
            "name" => "苹果"
          }
        }
      })

      product_item = Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product.id,
        status: "active",
        name: "Apple"
      })

      price = Repo.insert!(%Price{
        account_id: account1_id,
        product_item_id: product_item.id,
        status: "active",
        label: "regular",
        charge_cents: 1500,
        order_unit: "EA",
        charge_unit: "EA",
        translations: %{
          "zh-CN" => %{
            "name" => "原价"
          }
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = patch(conn, "/v1/prices/#{price.id}", %{
        "data" => %{
          "id" => price.id,
          "type" => "Price",
          "attributes" => @valid_attrs
        }
      })

      assert json_response(conn, 200)["data"]["id"] == price.id
      assert json_response(conn, 200)["data"]["attributes"]["status"] == @valid_attrs["status"]
      assert json_response(conn, 200)["data"]["attributes"]["name"] == @valid_attrs["name"]
      assert json_response(conn, 200)["data"]["attributes"]["chargeCents"] == @valid_attrs["chargeCents"]
    end

    test "with valid access token, attrs, rels and locale", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      product = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple",
        translations: %{
          "zh-CN" => %{
            "name" => "苹果"
          }
        }
      })

      product_item = Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product.id,
        status: "active",
        name: "Apple"
      })

      price = Repo.insert!(%Price{
        account_id: account1_id,
        product_item_id: product_item.id,
        status: "active",
        label: "regular",
        charge_cents: 1500,
        order_unit: "EA",
        charge_unit: "EA"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = patch(conn, "/v1/prices/#{price.id}?locale=zh-CN", %{
        "data" => %{
          "id" => price.id,
          "type" => "Price",
          "attributes" => %{
            "name" => "原价"
          }
        }
      })

      assert json_response(conn, 200)["data"]["id"] == price.id
      assert json_response(conn, 200)["data"]["attributes"]["status"] == @valid_attrs["status"]
      assert json_response(conn, 200)["data"]["attributes"]["name"] == "原价"
      assert json_response(conn, 200)["data"]["attributes"]["chargeCents"] == @valid_attrs["chargeCents"]
    end

    test "with valid access token, attrs, rels, locale and include", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      product = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple",
        translations: %{
          "zh-CN" => %{
            "name" => "苹果"
          }
        }
      })

      product_item = Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product.id,
        status: "active",
        name: "Apple"
      })

      price = Repo.insert!(%Price{
        account_id: account1_id,
        product_item_id: product_item.id,
        status: "active",
        label: "regular",
        charge_cents: 1500,
        order_unit: "EA",
        charge_unit: "EA"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = patch(conn, "/v1/prices/#{price.id}?locale=zh-CN&include=productItem.product", %{
        "data" => %{
          "id" => price.id,
          "type" => "Price",
          "attributes" => %{
            "name" => "原价"
          }
        }
      })

      assert json_response(conn, 200)["data"]["id"] == price.id
      assert json_response(conn, 200)["data"]["attributes"]["status"] == @valid_attrs["status"]
      assert json_response(conn, 200)["data"]["attributes"]["chargeCents"] == @valid_attrs["chargeCents"]
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "Product" end)) == 1
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["attributes"]["name"] == "苹果" end)) == 1
    end
  end

  describe "GET /v1/prices" do
    test "with no access token", %{ conn: conn } do
      conn = get(conn, "/v1/prices")

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

      product = Repo.insert!(%Product{
        account_id: account2_id,
        status: "active",
        name: "Apple",
        translations: %{
          "zh-CN" => %{
            "name" => "苹果"
          }
        }
      })

      product_item = Repo.insert!(%ProductItem{
        account_id: account2_id,
        product_id: product.id,
        status: "active",
        name: "Apple"
      })

      Repo.insert!(%Price{
        account_id: account2_id,
        product_item_id: product_item.id,
        status: "active",
        label: "regular",
        charge_cents: 1500,
        order_unit: "EA",
        charge_unit: "EA",
        translations: %{
          "zh-CN" => %{
            "name" => "原价"
          }
        }
      })

      product = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple",
        translations: %{
          "zh-CN" => %{
            "name" => "苹果"
          }
        }
      })

      product_item = Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product.id,
        status: "active",
        name: "Apple"
      })

      Repo.insert!(%Price{
        account_id: account1_id,
        product_item_id: product_item.id,
        status: "active",
        label: "regular",
        charge_cents: 1500,
        order_unit: "EA",
        charge_unit: "EA",
        translations: %{
          "zh-CN" => %{
            "name" => "原价"
          }
        }
      })

      Repo.insert!(%Price{
        account_id: account1_id,
        product_item_id: product_item.id,
        status: "active",
        label: "discounted",
        charge_cents: 1200,
        order_unit: "EA",
        charge_unit: "EA",
        translations: %{
          "zh-CN" => %{
            "name" => "特价"
          }
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/prices")

      assert length(json_response(conn, 200)["data"]) == 2
      assert json_response(conn, 200)["meta"]["resultCount"] == 2
      assert json_response(conn, 200)["meta"]["totalCount"] == 2
    end

    test "with valid access token and pagination", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      product = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple",
        translations: %{
          "zh-CN" => %{
            "name" => "苹果"
          }
        }
      })

      product_item = Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product.id,
        status: "active",
        name: "Apple"
      })

      Repo.insert!(%Price{
        account_id: account1_id,
        product_item_id: product_item.id,
        status: "active",
        label: "regular",
        charge_cents: 1500,
        order_unit: "EA",
        charge_unit: "EA",
        translations: %{
          "zh-CN" => %{
            "name" => "原价"
          }
        }
      })

      Repo.insert!(%Price{
        account_id: account1_id,
        product_item_id: product_item.id,
        status: "active",
        label: "regular",
        charge_cents: 1500,
        order_unit: "EA",
        charge_unit: "EA",
        translations: %{
          "zh-CN" => %{
            "name" => "原价"
          }
        }
      })

      Repo.insert!(%Price{
        account_id: account1_id,
        product_item_id: product_item.id,
        status: "active",
        label: "discounted",
        charge_cents: 1200,
        order_unit: "EA",
        charge_unit: "EA",
        translations: %{
          "zh-CN" => %{
            "name" => "特价"
          }
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/prices?page[number]=2&page[size]=1")

      assert length(json_response(conn, 200)["data"]) == 1
      assert json_response(conn, 200)["meta"]["resultCount"] == 3
      assert json_response(conn, 200)["meta"]["totalCount"] == 3
    end

    test "with valid access token and filter", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      product = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple",
        translations: %{
          "zh-CN" => %{
            "name" => "苹果"
          }
        }
      })

      product_item1 = Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product.id,
        status: "active",
        name: "Apple"
      })

      Repo.insert!(%Price{
        account_id: account1_id,
        product_item_id: product_item1.id,
        status: "active",
        label: "regular",
        charge_cents: 1500,
        order_unit: "EA",
        charge_unit: "EA",
        translations: %{
          "zh-CN" => %{
            "name" => "原价"
          }
        }
      })

      Repo.insert!(%Price{
        account_id: account1_id,
        product_item_id: product_item1.id,
        status: "active",
        label: "discounted",
        charge_cents: 1200,
        order_unit: "EA",
        charge_unit: "EA",
        translations: %{
          "zh-CN" => %{
            "name" => "特价"
          }
        }
      })

      product_item2 = Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product.id,
        status: "active",
        name: "Apple"
      })

      Repo.insert!(%Price{
        account_id: account1_id,
        product_item_id: product_item2.id,
        status: "active",
        label: "regular",
        charge_cents: 1500,
        order_unit: "EA",
        charge_unit: "EA",
        translations: %{
          "zh-CN" => %{
            "name" => "原价"
          }
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/prices?filter[productItemId]=#{product_item1.id}")

      assert length(json_response(conn, 200)["data"]) == 2
      assert json_response(conn, 200)["meta"]["resultCount"] == 2
      assert json_response(conn, 200)["meta"]["totalCount"] == 3
    end

    test "with valid access token and locale", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      product = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple",
        translations: %{
          "zh-CN" => %{
            "name" => "苹果"
          }
        }
      })

      product_item = Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product.id,
        status: "active",
        name: "Apple"
      })

      Repo.insert!(%Price{
        account_id: account1_id,
        product_item_id: product_item.id,
        status: "active",
        label: "regular",
        charge_cents: 1500,
        order_unit: "EA",
        charge_unit: "EA",
        translations: %{
          "zh-CN" => %{
            "name" => "原价"
          }
        }
      })

      Repo.insert!(%Price{
        account_id: account1_id,
        product_item_id: product_item.id,
        status: "active",
        label: "regular",
        charge_cents: 1500,
        order_unit: "EA",
        charge_unit: "EA",
        translations: %{
          "zh-CN" => %{
            "name" => "原价"
          }
        }
      })

      Repo.insert!(%Price{
        account_id: account1_id,
        product_item_id: product_item.id,
        status: "active",
        label: "discounted",
        charge_cents: 1200,
        order_unit: "EA",
        charge_unit: "EA",
        translations: %{
          "zh-CN" => %{
            "name" => "原价"
          }
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/prices?locale=zh-CN")

      assert length(json_response(conn, 200)["data"]) == 3
      assert json_response(conn, 200)["meta"]["resultCount"] == 3
      assert json_response(conn, 200)["meta"]["totalCount"] == 3
      assert length(Enum.filter(json_response(conn, 200)["data"], fn(item) -> item["attributes"]["name"] == "原价" end)) == 3
    end

    test "with valid access token and locale and search", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      product = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple",
        translations: %{
          "zh-CN" => %{
            "name" => "苹果"
          }
        }
      })

      product_item = Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product.id,
        status: "active",
        name: "Apple"
      })

      Repo.insert!(%Price{
        account_id: account1_id,
        product_item_id: product_item.id,
        status: "active",
        label: "regular",
        charge_cents: 1500,
        order_unit: "EA",
        charge_unit: "EA",
        translations: %{
          "zh-CN" => %{
            "name" => "原价"
          }
        }
      })

      Repo.insert!(%Price{
        account_id: account1_id,
        product_item_id: product_item.id,
        status: "active",
        label: "regular",
        charge_cents: 1500,
        order_unit: "EA",
        charge_unit: "EA",
        translations: %{
          "zh-CN" => %{
            "name" => "原价"
          }
        }
      })

      Repo.insert!(%Price{
        account_id: account1_id,
        product_item_id: product_item.id,
        status: "active",
        label: "discounted",
        charge_cents: 1200,
        order_unit: "EA",
        charge_unit: "EA",
        translations: %{
          "zh-CN" => %{
            "name" => "特价"
          }
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/prices?locale=zh-CN&search=原")

      assert length(json_response(conn, 200)["data"]) == 2
      assert json_response(conn, 200)["meta"]["resultCount"] == 2
      assert json_response(conn, 200)["meta"]["totalCount"] == 3
    end

    test "with valid access token, locale and include", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      product = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple",
        translations: %{
          "zh-CN" => %{
            "name" => "苹果"
          }
        }
      })

      product_item = Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product.id,
        status: "active",
        name: "Apple"
      })

      Repo.insert!(%Price{
        account_id: account1_id,
        product_item_id: product_item.id,
        status: "active",
        label: "regular",
        charge_cents: 1500,
        order_unit: "EA",
        charge_unit: "EA",
        translations: %{
          "zh-CN" => %{
            "name" => "原价"
          }
        }
      })

      Repo.insert!(%Price{
        account_id: account1_id,
        product_item_id: product_item.id,
        status: "active",
        label: "regular",
        charge_cents: 1500,
        order_unit: "EA",
        charge_unit: "EA",
        translations: %{
          "zh-CN" => %{
            "name" => "原价"
          }
        }
      })

      Repo.insert!(%Price{
        account_id: account1_id,
        product_item_id: product_item.id,
        status: "active",
        label: "discounted",
        charge_cents: 1200,
        order_unit: "EA",
        charge_unit: "EA",
        translations: %{
          "zh-CN" => %{
            "name" => "原价"
          }
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/prices?locale=zh-CN&include=productItem.product")

      assert length(json_response(conn, 200)["data"]) == 3
      assert json_response(conn, 200)["meta"]["resultCount"] == 3
      assert json_response(conn, 200)["meta"]["totalCount"] == 3
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "Product" end)) == 1
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "ProductItem" end)) == 1
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["attributes"]["name"] == "苹果" end)) == 1
    end
  end

  describe "DELETE /v1/prices/:id" do
    test "with no access token", %{ conn: conn } do
      conn = delete(conn, "/v1/prices/test")

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

      product = Repo.insert!(%Product{
        account_id: account2_id,
        status: "active",
        name: "Apple"
      })

      product_item = Repo.insert!(%ProductItem{
        account_id: account2_id,
        product_id: product.id,
        status: "active",
        name: "Apple"
      })

      price = Repo.insert!(%Price{
        account_id: account2_id,
        product_item_id: product_item.id,
        status: "active",
        label: "regular",
        charge_cents: 1500,
        order_unit: "EA",
        charge_unit: "EA"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      assert_error_sent(404, fn ->
        delete(conn, "/v1/prices/#{price.id}")
      end)
    end

    test "with valid access token and id", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      product = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple"
      })

      product_item = Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product.id,
        status: "active",
        name: "Apple"
      })

      price = Repo.insert!(%Price{
        account_id: account1_id,
        product_item_id: product_item.id,
        status: "active",
        label: "regular",
        charge_cents: 1500,
        order_unit: "EA",
        charge_unit: "EA"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = delete(conn, "/v1/prices/#{price.id}")

      assert conn.status == 204
    end
  end
end