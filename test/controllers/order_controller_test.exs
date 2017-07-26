defmodule BlueJet.OrderControllerTest do
  use BlueJet.ConnCase

  alias BlueJet.User
  alias BlueJet.UserRegistration
  alias BlueJet.Authentication
  alias BlueJet.Customer
  alias BlueJet.RefreshToken

  alias BlueJet.Repo

  @valid_attrs %{
    "status" => "cart"
  }
  @invalid_attrs %{
    "status" => "opened"
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

    customer = Repo.insert!(%Customer{
      account_id: account1_id
    })
    refresh_token = Repo.insert!(%RefreshToken{
      account_id: account1_id,
      customer_id: customer.id
    })
    {:ok, %{ access_token: cat1 }} = Authentication.get_token(%{ refresh_token: refresh_token.id })

    conn = build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{ conn: conn, uat1: uat1, cat1: cat1, account1_id: account1_id }
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

    @tag :focus
    test "with invalid attrs and rels", %{ conn: conn, uat1: uat1 } do
      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = post(conn, "/v1/orders", %{
        "data" => %{
          "type" => "Order",
          "attributes" => @invalid_attrs
        }
      })

      IO.inspect json_response(conn, 422)["errors"]
      assert json_response(conn, 422)["errors"]
      assert length(json_response(conn, 422)["errors"]) > 0
    end

    # test "with valid attrs and rels", %{ conn: conn, uat1: uat1 } do
    #   conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

    #   conn = post(conn, "/v1/products", %{
    #     "data" => %{
    #       "type" => "Product",
    #       "attributes" => @valid_attrs
    #     }
    #   })

    #   assert json_response(conn, 201)["data"]["id"]
    #   assert json_response(conn, 201)["data"]["attributes"]["status"] == @valid_attrs["status"]
    #   assert json_response(conn, 201)["data"]["attributes"]["name"] == @valid_attrs["name"]
    #   assert json_response(conn, 201)["data"]["attributes"]["customData"] == @valid_attrs["customData"]
    #   assert json_response(conn, 201)["data"]["attributes"]["customData"]["kind"] == @valid_attrs["customData"]["kind"]
    # end

    # test "with valid attrs, rels and include", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
    #   %ExternalFile{ id: avatar_id } = Repo.insert!(%ExternalFile{
    #     account_id: account1_id,
    #     name: Faker.Lorem.word(),
    #     status: "uploaded",
    #     content_type: "image/png",
    #     size_bytes: 42
    #   })

    #   conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

    #   conn = post(conn, "/v1/products?include=avatar", %{
    #     "data" => %{
    #       "type" => "Product",
    #       "attributes" => @valid_attrs,
    #       "relationships" => %{
    #         "avatar" => %{
    #           "data" => %{
    #             "type" => "ExternalFile",
    #             "id" => avatar_id
    #           }
    #         }
    #       }
    #     }
    #   })

    #   assert json_response(conn, 201)["data"]["id"]
    #   assert json_response(conn, 201)["data"]["attributes"]["status"] == @valid_attrs["status"]
    #   assert json_response(conn, 201)["data"]["attributes"]["name"] == @valid_attrs["name"]
    #   assert json_response(conn, 201)["data"]["attributes"]["customData"] == @valid_attrs["customData"]
    #   assert json_response(conn, 201)["data"]["attributes"]["customData"]["kind"] == @valid_attrs["customData"]["kind"]
    #   assert json_response(conn, 201)["data"]["relationships"]["avatar"]["data"]["id"]
    #   assert length(Enum.filter(json_response(conn, 201)["included"], fn(item) -> item["type"] == "ExternalFile" end)) == 1
    # end
  end

  # describe "GET /v1/products/:id" do
  #   test "with no access token", %{ conn: conn } do
  #     conn = get(conn, "/v1/products/test")

  #     assert conn.status == 401
  #   end

  #   test "with access token of a different account", %{ conn: conn, uat1: uat1 } do
  #     {_, %User{ default_account_id: account2_id }} = UserRegistration.sign_up(%{
  #       first_name: Faker.Name.first_name(),
  #       last_name: Faker.Name.last_name(),
  #       email: "test2@example.com",
  #       password: "test1234",
  #       account_name: Faker.Company.name()
  #     })

  #     product = Repo.insert!(
  #       Map.merge(%Product{ account_id: account2_id }, @valid_fields)
  #     )

  #     conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

  #     assert_error_sent(404, fn ->
  #       get(conn, "/v1/products/#{product.id}")
  #     end)
  #   end

  #   test "with valid access token and id", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
  #     product = Repo.insert!(
  #       Map.merge(%Product{ account_id: account1_id }, @valid_fields)
  #     )

  #     conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

  #     conn = get(conn, "/v1/products/#{product.id}")

  #     assert json_response(conn, 200)["data"]["id"] == product.id
  #     assert json_response(conn, 200)["data"]["attributes"]["status"] == product.status
  #     assert json_response(conn, 200)["data"]["attributes"]["name"] == product.name
  #     assert json_response(conn, 200)["data"]["attributes"]["customData"] == product.custom_data
  #   end

  #   test "with valid access token, id, locale and include", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
  #     product = Repo.insert!(
  #       Map.merge(%Product{
  #         account_id: account1_id,
  #         translations: %{
  #           "zh-CN" => %{
  #             "name" => "橙子"
  #           }
  #         }
  #       },
  #       @valid_fields)
  #     )

  #     Repo.insert!(%ExternalFileCollection{
  #       account_id: account1_id,
  #       product_id: product.id,
  #       label: "primary_images",
  #       translations: %{
  #         "zh-CN" => %{
  #           "name" => "图片"
  #         }
  #       }
  #     })

  #     conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

  #     conn = get(conn, "/v1/products/#{product.id}?locale=zh-CN&include=externalFileCollections")

  #     assert json_response(conn, 200)["data"]["id"] == product.id
  #     assert json_response(conn, 200)["data"]["attributes"]["status"] == product.status
  #     assert json_response(conn, 200)["data"]["attributes"]["name"] == "橙子"
  #     assert json_response(conn, 200)["data"]["attributes"]["customData"] == product.custom_data
  #     assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "ExternalFileCollection" end)) == 1
  #     assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["attributes"]["name"] == "图片" end)) == 1
  #   end
  # end

  # describe "PATCH /v1/products/:id" do
  #   test "with no access token", %{ conn: conn } do
  #     conn = patch(conn, "/v1/products/test", %{
  #       "data" => %{
  #         "id" => "test",
  #         "type" => "Product",
  #         "attributes" => @valid_attrs
  #       }
  #     })

  #     assert conn.status == 401
  #   end

  #   test "with access token of a different account", %{ conn: conn, uat1: uat1 } do
  #     {_, %User{ default_account_id: account2_id }} = UserRegistration.sign_up(%{
  #       first_name: Faker.Name.first_name(),
  #       last_name: Faker.Name.last_name(),
  #       email: "test2@example.com",
  #       password: "test1234",
  #       account_name: Faker.Company.name()
  #     })

  #     product = Repo.insert!(
  #       Map.merge(%Product{ account_id: account2_id }, @valid_fields)
  #     )

  #     conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

  #     assert_error_sent(404, fn ->
  #       patch(conn, "/v1/products/#{product.id}", %{
  #         "data" => %{
  #           "id" => product.id,
  #           "type" => "Product",
  #           "attributes" => @valid_attrs
  #         }
  #       })
  #     end)
  #   end

  #   test "with valid access token, invalid attrs and rels", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
  #     product = Repo.insert!(
  #       Map.merge(%Product{ account_id: account1_id }, @valid_fields)
  #     )

  #     conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

  #     conn = patch(conn, "/v1/products/#{product.id}", %{
  #       "data" => %{
  #         "id" => product.id,
  #         "type" => "Product",
  #         "attributes" => @invalid_attrs
  #       }
  #     })

  #     assert json_response(conn, 422)["errors"]
  #     assert length(json_response(conn, 422)["errors"]) > 0
  #   end

  #   test "with valid access token, attrs and rels", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
  #     product = Repo.insert!(
  #       Map.merge(%Product{ account_id: account1_id }, @valid_fields)
  #     )

  #     conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

  #     conn = patch(conn, "/v1/products/#{product.id}", %{
  #       "data" => %{
  #         "id" => product.id,
  #         "type" => "Product",
  #         "attributes" => @valid_attrs
  #       }
  #     })

  #     assert json_response(conn, 200)["data"]["id"]
  #     assert json_response(conn, 200)["data"]["attributes"]["status"] == @valid_attrs["status"]
  #     assert json_response(conn, 200)["data"]["attributes"]["name"] == @valid_attrs["name"]
  #     assert json_response(conn, 200)["data"]["attributes"]["customData"]["kind"] == @valid_attrs["customData"]["kind"]
  #   end

  #   test "with valid access token, attrs, rels and locale", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
  #     product = Repo.insert!(
  #       Map.merge(%Product{
  #         account_id: account1_id
  #       },
  #       @valid_fields)
  #     )

  #     conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

  #     conn = patch(conn, "/v1/products/#{product.id}?locale=zh-CN", %{
  #       "data" => %{
  #         "id" => product.id,
  #         "type" => "Product",
  #         "attributes" => %{
  #           "name" => "橙子"
  #         }
  #       }
  #     })

  #     assert json_response(conn, 200)["data"]["id"]
  #     assert json_response(conn, 200)["data"]["attributes"]["status"] == @valid_fields[:status]
  #     assert json_response(conn, 200)["data"]["attributes"]["name"] == "橙子"
  #     assert json_response(conn, 200)["data"]["attributes"]["customData"] == @valid_fields[:custom_data]
  #   end

  #   test "with valid access token, attrs, rels, locale and include", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
  #     product = Repo.insert!(
  #       Map.merge(%Product{
  #         account_id: account1_id
  #       },
  #       @valid_fields)
  #     )

  #     Repo.insert!(%ExternalFileCollection{
  #       account_id: account1_id,
  #       product_id: product.id,
  #       label: "primary_images",
  #       translations: %{
  #         "zh-CN" => %{
  #           "name" => "图片"
  #         }
  #       }
  #     })

  #     conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

  #     conn = patch(conn, "/v1/products/#{product.id}?locale=zh-CN&include=externalFileCollections", %{
  #       "data" => %{
  #         "id" => product.id,
  #         "type" => "Product",
  #         "attributes" => %{
  #           "name" => "橙子"
  #         }
  #       }
  #     })

  #     assert json_response(conn, 200)["data"]["id"]
  #     assert json_response(conn, 200)["data"]["attributes"]["status"] == @valid_fields[:status]
  #     assert json_response(conn, 200)["data"]["attributes"]["name"] == "橙子"
  #     assert json_response(conn, 200)["data"]["attributes"]["customData"] == @valid_fields[:custom_data]
  #     assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "ExternalFileCollection" end)) == 1
  #     assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["attributes"]["name"] == "图片" end)) == 1
  #   end
  # end

  # describe "GET /v1/products" do
  #   test "with no access token", %{ conn: conn } do
  #     conn = get(conn, "/v1/products")

  #     assert conn.status == 401
  #   end

  #   test "with valid access token", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
  #     {_, %User{ default_account_id: account2_id }} = UserRegistration.sign_up(%{
  #       first_name: Faker.Name.first_name(),
  #       last_name: Faker.Name.last_name(),
  #       email: "test2@example.com",
  #       password: "test1234",
  #       account_name: Faker.Company.name()
  #     })

  #     Repo.insert!(
  #       Map.merge(%Product{ account_id: account2_id }, @valid_fields)
  #     )
  #     Repo.insert!(
  #       Map.merge(%Product{ account_id: account1_id }, @valid_fields)
  #     )
  #     Repo.insert!(
  #       Map.merge(%Product{ account_id: account1_id }, @valid_fields)
  #     )

  #     conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

  #     conn = get(conn, "/v1/products")

  #     assert length(json_response(conn, 200)["data"]) == 2
  #   end

  #   test "with valid access token and pagination", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
  #     Repo.insert!(%Product{
  #       account_id: account1_id,
  #       status: "active",
  #       name: "Apple"
  #     })

  #     Repo.insert!(%Product{
  #       account_id: account1_id,
  #       status: "active",
  #       name: "Apple"
  #     })

  #     Repo.insert!(%Product{
  #       account_id: account1_id,
  #       status: "active",
  #       name: "Apple"
  #     })

  #     conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

  #     conn = get(conn, "/v1/products?page[number]=2&page[size]=1")

  #     assert length(json_response(conn, 200)["data"]) == 1
  #     assert json_response(conn, 200)["meta"]["resultCount"] == 3
  #     assert json_response(conn, 200)["meta"]["totalCount"] == 3
  #   end

  #   test "with valid access token and filter", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
  #     Repo.insert!(%Product{
  #       account_id: account1_id,
  #       status: "active",
  #       name: "Apple"
  #     })

  #     Repo.insert!(%Product{
  #       account_id: account1_id,
  #       status: "active",
  #       name: "Apple"
  #     })

  #     Repo.insert!(%Product{
  #       account_id: account1_id,
  #       status: "disabled",
  #       name: "Apple"
  #     })

  #     conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

  #     conn = get(conn, "/v1/products?filter[status]=active")

  #     assert length(json_response(conn, 200)["data"]) == 2
  #     assert json_response(conn, 200)["meta"]["resultCount"] == 2
  #     assert json_response(conn, 200)["meta"]["totalCount"] == 3
  #   end

  #   test "with valid access token and locale", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
  #     Repo.insert!(%Product{
  #       account_id: account1_id,
  #       status: "active",
  #       name: "Apple",
  #       translations: %{
  #         "zh-CN" => %{
  #           "name" => "苹果"
  #         }
  #       }
  #     })

  #     Repo.insert!(%Product{
  #       account_id: account1_id,
  #       status: "active",
  #       name: "Apple",
  #       translations: %{
  #         "zh-CN" => %{
  #           "name" => "苹果"
  #         }
  #       }
  #     })

  #     Repo.insert!(%Product{
  #       account_id: account1_id,
  #       status: "active",
  #       name: "Apple"
  #     })

  #     conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

  #     conn = get(conn, "/v1/products?locale=zh-CN")

  #     assert length(json_response(conn, 200)["data"]) == 3
  #     assert json_response(conn, 200)["meta"]["resultCount"] == 3
  #     assert json_response(conn, 200)["meta"]["totalCount"] == 3
  #     assert length(Enum.filter(json_response(conn, 200)["data"], fn(item) -> item["attributes"]["name"] == "苹果" end)) == 2
  #   end

  #   test "with valid access token, locale and search", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
  #     Repo.insert!(%Product{
  #       account_id: account1_id,
  #       status: "active",
  #       name: "Apple",
  #       translations: %{
  #         "zh-CN" => %{
  #           "name" => "苹果"
  #         }
  #       }
  #     })

  #     Repo.insert!(%Product{
  #       account_id: account1_id,
  #       status: "active",
  #       name: "Apple",
  #       translations: %{
  #         "zh-CN" => %{
  #           "name" => "苹果"
  #         }
  #       }
  #     })

  #     Repo.insert!(%Product{
  #       account_id: account1_id,
  #       status: "active",
  #       name: "Apple"
  #     })

  #     conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

  #     conn = get(conn, "/v1/products?locale=zh-CN&search=苹")

  #     assert length(json_response(conn, 200)["data"]) == 2
  #     assert json_response(conn, 200)["meta"]["resultCount"] == 2
  #     assert json_response(conn, 200)["meta"]["totalCount"] == 3
  #     assert length(Enum.filter(json_response(conn, 200)["data"], fn(item) -> item["attributes"]["name"] == "苹果" end)) == 2
  #   end

  #   test "with valid access token, locale and include", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
  #     Repo.insert!(%Product{
  #       account_id: account1_id,
  #       status: "active",
  #       name: "Apple",
  #       translations: %{
  #         "zh-CN" => %{
  #           "name" => "苹果"
  #         }
  #       }
  #     })

  #     Repo.insert!(%Product{
  #       account_id: account1_id,
  #       status: "active",
  #       name: "Apple",
  #       translations: %{
  #         "zh-CN" => %{
  #           "name" => "苹果"
  #         }
  #       }
  #     })

  #     product = Repo.insert!(%Product{
  #       account_id: account1_id,
  #       status: "active",
  #       name: "Apple"
  #     })

  #     Repo.insert!(%ExternalFileCollection{
  #       account_id: account1_id,
  #       product_id: product.id,
  #       label: "primary_images",
  #       translations: %{
  #         "zh-CN" => %{
  #           "name" => "图片"
  #         }
  #       }
  #     })

  #     conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

  #     conn = get(conn, "/v1/products?locale=zh-CN&include=externalFileCollections")

  #     assert length(json_response(conn, 200)["data"]) == 3
  #     assert json_response(conn, 200)["meta"]["resultCount"] == 3
  #     assert json_response(conn, 200)["meta"]["totalCount"] == 3
  #     assert length(Enum.filter(json_response(conn, 200)["data"], fn(item) -> item["attributes"]["name"] == "苹果" end)) == 2
  #     assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["type"] == "ExternalFileCollection" end)) == 1
  #     assert length(Enum.filter(json_response(conn, 200)["included"], fn(item) -> item["attributes"]["name"] == "图片" end)) == 1
  #   end
  # end

  # describe "DELETE /v1/products/:id" do
  #   test "with no access token", %{ conn: conn } do
  #     conn = delete(conn, "/v1/products/test")

  #     assert conn.status == 401
  #   end

  #   test "with access token of a different account", %{ conn: conn, uat1: uat1 } do
  #     {_, %User{ default_account_id: account2_id }} = UserRegistration.sign_up(%{
  #       first_name: Faker.Name.first_name(),
  #       last_name: Faker.Name.last_name(),
  #       email: "test2@example.com",
  #       password: "test1234",
  #       account_name: Faker.Company.name()
  #     })

  #     product = Repo.insert!(
  #       Map.merge(%Product{ account_id: account2_id }, @valid_fields)
  #     )

  #     conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

  #     assert_error_sent(404, fn ->
  #       delete(conn, "/v1/products/#{product.id}")
  #     end)
  #   end

  #   test "with valid access token and id", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
  #     product = Repo.insert!(
  #       Map.merge(%Product{ account_id: account1_id }, @valid_fields)
  #     )

  #     conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

  #     conn = delete(conn, "/v1/products/#{product.id}")

  #     assert conn.status == 204
  #   end
  # end
end
