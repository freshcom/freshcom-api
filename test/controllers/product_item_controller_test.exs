defmodule BlueJet.ProductItemControllerTest do
  use BlueJet.ConnCase

  alias BlueJet.User
  alias BlueJet.UserRegistration
  alias BlueJet.Authentication

  alias BlueJet.Product
  alias BlueJet.Sku
  alias BlueJet.ProductItem
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

  describe "POST /v1/products/:id/items" do
    test "with no access token", %{ conn: conn } do
      conn = post(conn, product_product_item_path(conn, :create, Ecto.UUID.generate()), %{
        "data" => %{
          "type" => "ProductItem",
          "attributes" => @valid_attrs
        }
      })

      assert conn.status == 401
    end

    test "with invalid attrs", %{ conn: conn, uat1: uat1 } do
      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = post(conn, product_product_item_path(conn, :create, Ecto.UUID.generate()), %{
        "data" => %{
          "type" => "ProductItem",
          "attributes" => @invalid_attrs
        }
      })

      assert json_response(conn, 422)["errors"]
      assert length(json_response(conn, 422)["errors"]) > 0
    end

    test "with valid attrs and valid rels", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
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

      conn = post(conn, product_product_item_path(conn, :create, product_id), %{
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
  end

  describe "GET /v1/product_items/:id" do
    test "with no access token", %{ conn: conn } do
      conn = get(conn, product_item_path(conn, :show, "test"))

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

      %ProductItem{ id: product_item_id } = Repo.insert!(%ProductItem{
        account_id: account2_id,
        product_id: product_id,
        sku_id: sku_id,
        status: "active",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      assert_error_sent(404, fn ->
        get(conn, product_item_path(conn, :show, product_item_id))
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

      %ProductItem{ id: product_item_id } = Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product_id,
        sku_id: sku_id,
        status: "active",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, product_item_path(conn, :show, product_item_id, include: "product,sku"))

      assert json_response(conn, 200)["data"]["id"] == product_item_id
      assert json_response(conn, 200)["data"]["attributes"]["status"] == @valid_attrs["status"]
      assert json_response(conn, 200)["data"]["relationships"]["sku"]["data"]["id"] == sku_id
      assert json_response(conn, 200)["data"]["relationships"]["product"]["data"]["id"] == product_id
    end
  end

  describe "PATCH /v1/product_items/:id" do
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

      %ProductItem{ id: product_item_id } = Repo.insert!(%ProductItem{
        account_id: account2_id,
        product_id: product_id,
        sku_id: sku_id,
        status: "active",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      assert_error_sent(404, fn ->
        patch(conn, product_item_path(conn, :update, product_item_id), %{
          "data" => %{
            "id" => product_item_id,
            "type" => "ProductItem",
            "attributes" => @valid_attrs
          }
        })
      end)
    end

    test "with good access token but invalid attrs", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      %Product{ id: product_id } = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple"
      })

      %ProductItem{ id: product_item_id } = Repo.insert!(%ProductItem{
        product_id: product_id,
        account_id: account1_id,
        status: "active",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = patch(conn, product_item_path(conn, :update, product_item_id), %{
        "data" => %{
          "id" => product_item_id,
          "type" => "ProductItem",
          "attributes" => @invalid_attrs
        }
      })

      assert json_response(conn, 422)["errors"]
      assert length(json_response(conn, 422)["errors"]) > 0
    end

    test "with good access token and valid attrs", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
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

      %ProductItem{ id: product_item_id } = Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product_id,
        sku_id: sku_id,
        status: "active",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = patch(conn, product_item_path(conn, :update, product_item_id), %{
        "data" => %{
          "id" => product_item_id,
          "type" => "ProductItem",
          "attributes" => @valid_attrs
        }
      })

      assert json_response(conn, 200)["data"]["id"]
      assert json_response(conn, 200)["data"]["attributes"]["status"] == @valid_attrs["status"]
      assert json_response(conn, 200)["data"]["attributes"]["customData"] == @valid_attrs["customData"]
    end
  end

  describe "GET /v1/product_items" do
    test "with no access token", %{ conn: conn } do
      conn = get(conn, product_item_path(conn, :index))

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
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, product_item_path(conn, :index))

      assert length(json_response(conn, 200)["data"]) == 2
    end

    @tag :focus
    test "with good access token, locale, include and filter", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
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

      conn = get(conn, product_item_path(conn, :index, include: "product,sku", filter: %{ "skuId" => sku1_id }, locale: "zh-CN"))

      assert length(json_response(conn, 200)["data"]) == 2
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "Product" end)) == 2
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "Sku" end)) == 1
    end
  end

  describe "DELETE /v1/product_items/:id" do
    test "with no access token", %{ conn: conn } do
      conn = delete(conn, product_item_path(conn, :delete, "test"))

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

      %ProductItem{ id: product_item_id } = Repo.insert!(%ProductItem{
        account_id: account2_id,
        product_id: product_id,
        sku_id: sku_id,
        status: "active",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      assert_error_sent(404, fn ->
        delete(conn, product_item_path(conn, :delete, product_item_id))
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

      %ProductItem{ id: product_item_id } = Repo.insert!(%ProductItem{
        account_id: account1_id,
        product_id: product_id,
        sku_id: sku_id,
        status: "active",
        custom_data: %{
          "kind" => "Blue Jay"
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = delete(conn, product_item_path(conn, :delete, product_item_id))

      assert conn.status == 204
    end
  end
end
