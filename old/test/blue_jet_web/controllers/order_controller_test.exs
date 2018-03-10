defmodule BlueJetWeb.OrderControllerTest do
  use BlueJetWeb.ConnCase

  alias BlueJet.Identity.User
  alias BlueJet.Identity.Customer
  alias BlueJet.Identity.RefreshToken

  alias BlueJet.Repo
  alias BlueJet.Storefront.Order

  @valid_attrs %{
    "status" => "cart",
    "firstName" => "Roy",
    "customData" => %{
      "ccc" => "hi"
    }
  }
  @invalid_attrs %{
    "status" => "opened"
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

    customer1 = Repo.insert!(%Customer{
      account_id: account1_id
    })
    refresh_token = Repo.insert!(%RefreshToken{
      account_id: account1_id,
      customer_id: customer1.id
    })
    {:ok, %{ access_token: cat1 }} = Identity.authenticate(%{ refresh_token: refresh_token.id })

    conn = build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{ conn: conn, uat1: uat1, cat1: cat1, customer1_id: customer1.id, account1_id: account1_id }
  end

  describe "POST /v1/orders" do
    test "with no access token", %{ conn: conn } do
      conn = post(conn, "/v1/orders", %{
        "data" => %{
          "type" => "Order",
          "attributes" => @valid_attrs
        }
      })

      assert conn.status == 401
    end

    test "with invalid attrs and rels", %{ conn: conn, uat1: uat1 } do
      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = post(conn, "/v1/orders", %{
        "data" => %{
          "type" => "Order",
          "attributes" => @invalid_attrs
        }
      })

      assert json_response(conn, 422)["errors"]
      assert length(json_response(conn, 422)["errors"]) > 0
    end

    test "with valid attrs and rels", %{ conn: conn, uat1: uat1 } do
      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = post(conn, "/v1/orders", %{
        "data" => %{
          "type" => "Order",
          "attributes" => @valid_attrs
        }
      })

      assert json_response(conn, 201)["data"]["id"]
      assert json_response(conn, 201)["data"]["attributes"]["customData"] == @valid_attrs["customData"]
    end

    test "with valid attrs, rels and include", %{ conn: conn, uat1: uat1, customer1_id: customer1_id } do
      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = post(conn, "/v1/orders?include=customer", %{
        "data" => %{
          "type" => "Order",
          "attributes" => @valid_attrs,
          "relationships" => %{
            "customer" => %{
              "data" => %{
                "type" => "Customer",
                "id" => customer1_id
              }
            }
          }
        }
      })

      assert json_response(conn, 201)["data"]["id"]
      assert json_response(conn, 201)["data"]["relationships"]["customer"]["data"]["id"] == customer1_id
      assert length(Enum.filter(json_response(conn, 201)["included"], fn(item) -> item["type"] == "Customer" end)) == 1
    end
  end

  describe "GET /v1/orders/:id" do
    test "with no access token", %{ conn: conn } do
      conn = get(conn, "/v1/orders/test")

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

      order = Repo.insert!(%Order{
        account_id: account2_id,
        status: "cart"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      assert_error_sent(404, fn ->
        get(conn, "/v1/orders/#{order.id}")
      end)
    end

    test "with access token of a different customer", %{ conn: conn, account1_id: account1_id, cat1: cat1 } do
      order = Repo.insert!(%Order{
        account_id: account1_id,
        status: "cart"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{cat1}")

      assert_error_sent(404, fn ->
        get(conn, "/v1/orders/#{order.id}")
      end)
    end

    test "with valid access token and id", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      order = Repo.insert!(%Order{
        account_id: account1_id,
        status: "cart"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/orders/#{order.id}")

      assert json_response(conn, 200)["data"]["id"] == order.id
      assert json_response(conn, 200)["data"]["attributes"]["status"] == order.status
    end

    test "with valid access token, id and include", %{ conn: conn, uat1: uat1, account1_id: account1_id, customer1_id: customer1_id } do
      order = Repo.insert!(%Order{
        account_id: account1_id,
        customer_id: customer1_id,
        status: "cart"
      })


      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/orders/#{order.id}?include=customer")

      assert json_response(conn, 200)["data"]["id"] == order.id
      assert json_response(conn, 200)["data"]["attributes"]["status"] == order.status
      assert json_response(conn, 200)["data"]["relationships"]["customer"]["data"]["id"] == customer1_id
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "Customer" end)) == 1
    end
  end

  describe "PATCH /v1/orders/:id" do
    test "with no access token", %{ conn: conn } do
      conn = patch(conn, "/v1/orders/test", %{
        "data" => %{
          "id" => "test",
          "type" => "Order",
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

      order = Repo.insert!(%Order{
        account_id: account2_id,
        status: "cart"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      assert_error_sent(404, fn ->
        patch(conn, "/v1/orders/#{order.id}", %{
          "data" => %{
            "id" => order.id,
            "type" => "Order",
            "attributes" => @valid_attrs
          }
        })
      end)
    end

    test "with valid access token, invalid attrs and rels", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      order = Repo.insert!(%Order{
        account_id: account1_id,
        status: "cart"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = patch(conn, "/v1/orders/#{order.id}", %{
        "data" => %{
          "id" => order.id,
          "type" => "Order",
          "attributes" => @invalid_attrs
        }
      })

      assert json_response(conn, 422)["errors"]
      assert length(json_response(conn, 422)["errors"]) > 0
    end

    test "with valid access token, attrs and rels", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      order = Repo.insert!(%Order{
        account_id: account1_id,
        status: "cart"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = patch(conn, "/v1/orders/#{order.id}", %{
        "data" => %{
          "id" => order.id,
          "type" => "Order",
          "attributes" => @valid_attrs
        }
      })

      assert json_response(conn, 200)["data"]["id"]
      assert json_response(conn, 200)["data"]["attributes"]["status"] == @valid_attrs["status"]
      assert json_response(conn, 200)["data"]["attributes"]["firstName"] == @valid_attrs["firstName"]
    end

    test "with valid access token, attrs, rels and include", %{ conn: conn, uat1: uat1, account1_id: account1_id, customer1_id: customer1_id } do
      order = Repo.insert!(%Order{
        account_id: account1_id,
        status: "cart"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = patch(conn, "/v1/orders/#{order.id}?include=customer", %{
        "data" => %{
          "id" => order.id,
          "type" => "Order",
          "attributes" => @valid_attrs,
          "relationships" => %{
            "customer" => %{
              "data" => %{
                "type" => "Customer",
                "id" => customer1_id
              }
            }
          }
        }
      })

      assert json_response(conn, 200)["data"]["id"]
      assert json_response(conn, 200)["data"]["relationships"]["customer"]["data"]["id"] == customer1_id
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "Customer" end)) == 1
    end
  end

  describe "GET /v1/orders" do
    test "with no access token", %{ conn: conn } do
      conn = get(conn, "/v1/orders")

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

      Repo.insert!(%Order{
        account_id: account1_id,
        status: "opened"
      })
      Repo.insert!(%Order{
        account_id: account1_id,
        status: "opened"
      })
      Repo.insert!(%Order{
        account_id: account1_id,
        status: "cart"
      })
      Repo.insert!(%Order{
        account_id: account2_id,
        status: "opened"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/orders")

      assert length(json_response(conn, 200)["data"]) == 2
    end

    test "with valid access token and pagination", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      Repo.insert!(%Order{
        account_id: account1_id,
        status: "opened"
      })
      Repo.insert!(%Order{
        account_id: account1_id,
        status: "opened"
      })
      Repo.insert!(%Order{
        account_id: account1_id,
        status: "opened"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/orders?page[number]=2&page[size]=1")

      assert length(json_response(conn, 200)["data"]) == 1
      assert json_response(conn, 200)["meta"]["resultCount"] == 3
      assert json_response(conn, 200)["meta"]["totalCount"] == 3
    end

    test "with valid access token and filter", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      Repo.insert!(%Order{
        account_id: account1_id,
        status: "opened"
      })
      Repo.insert!(%Order{
        account_id: account1_id,
        status: "cart"
      })
      Repo.insert!(%Order{
        account_id: account1_id,
        status: "cart"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/orders?filter[status]=cart")

      assert length(json_response(conn, 200)["data"]) == 2
      assert json_response(conn, 200)["meta"]["resultCount"] == 2
      assert json_response(conn, 200)["meta"]["totalCount"] == 3
    end

    test "with valid access token and locale", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      Repo.insert!(%Order{
        account_id: account1_id,
        status: "opened",
        translations: %{
          "zh-CN" => %{
            "custom_data" => %{
              "custom1" => "中文"
            }
          }
        }
      })
      Repo.insert!(%Order{
        account_id: account1_id,
        status: "opened"
      })
      Repo.insert!(%Order{
        account_id: account1_id,
        status: "opened"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/orders?locale=zh-CN")

      assert length(json_response(conn, 200)["data"]) == 3
      assert json_response(conn, 200)["meta"]["resultCount"] == 3
      assert json_response(conn, 200)["meta"]["totalCount"] == 3
      assert length(Enum.filter(json_response(conn, 200)["data"], fn(item) -> item["attributes"]["customData"]["custom1"] == "中文" end)) == 1
    end

    test "with valid access token and search", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      Repo.insert!(%Order{
        account_id: account1_id,
        status: "opened",
        code: "APPLE-01"
      })
      Repo.insert!(%Order{
        account_id: account1_id,
        status: "opened"
      })
      Repo.insert!(%Order{
        account_id: account1_id,
        status: "opened"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/orders?search=apple")

      assert length(json_response(conn, 200)["data"]) == 1
      assert json_response(conn, 200)["meta"]["resultCount"] == 1
      assert json_response(conn, 200)["meta"]["totalCount"] == 3
    end

    test "with valid access token and include", %{ conn: conn, uat1: uat1, account1_id: account1_id, customer1_id: customer1_id } do
      Repo.insert!(%Order{
        account_id: account1_id,
        status: "opened",
        customer_id: customer1_id
      })
      Repo.insert!(%Order{
        account_id: account1_id,
        status: "opened",
        customer_id: customer1_id
      })
      Repo.insert!(%Order{
        account_id: account1_id,
        status: "opened",
        customer_id: customer1_id
      })
      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/orders?include=customer")

      assert length(json_response(conn, 200)["data"]) == 3
      assert json_response(conn, 200)["meta"]["resultCount"] == 3
      assert json_response(conn, 200)["meta"]["totalCount"] == 3
      assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "Customer" end)) == 1
    end
  end

  describe "DELETE /v1/orders/:id" do
    test "with no access token", %{ conn: conn } do
      conn = delete(conn, "/v1/orders/test")

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

      order = Repo.insert!(%Order{
        account_id: account2_id,
        status: "opened"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      assert_error_sent(404, fn ->
        delete(conn, "/v1/orders/#{order.id}")
      end)
    end

    test "with valid access token and id", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      order = Repo.insert!(%Order{
        account_id: account1_id,
        status: "opened"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = delete(conn, "/v1/orders/#{order.id}")

      assert conn.status == 204
    end
  end
end
