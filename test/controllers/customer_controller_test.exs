defmodule BlueJet.CustomerControllerTest do
  use BlueJet.ConnCase

  alias BlueJet.User
  alias BlueJet.UserRegistration
  alias BlueJet.Authentication
  alias BlueJet.RefreshToken

  alias BlueJet.Customer
  alias BlueJet.Repo

  @valid_attrs %{
    "firstName" => "Roy",
    "lastName" => "Bao",
    "customData" => %{
      "kind" => "Good Person"
    }
  }
  @invalid_attrs %{
    "status" => "member"
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

    refresh_token = from(rt in RefreshToken, where: rt.account_id == ^account1_id and is_nil(rt.user_id) and is_nil(rt.customer_id)) |> Repo.one()
    {:ok, %{ access_token: sat1 }} = Authentication.get_token(%{ refresh_token: refresh_token.id })

    conn = build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{ conn: conn, uat1: uat1, sat1: sat1, account1_id: account1_id }
  end

  describe "POST /v1/customers" do
    test "with no access token", %{ conn: conn } do
      conn = post(conn, "/v1/customers", %{
        "data" => %{
          "type" => "Customer",
          "attributes" => @valid_attrs
        }
      })

      assert conn.status == 401
    end

    test "with invalid attrs and rels", %{ conn: conn, sat1: sat1 } do
      conn = put_req_header(conn, "authorization", "Bearer #{sat1}")

      conn = post(conn, "/v1/customers", %{
        "data" => %{
          "type" => "Customer",
          "attributes" => @invalid_attrs
        }
      })

      assert json_response(conn, 422)["errors"]
      assert length(json_response(conn, 422)["errors"]) > 0
    end

    test "with valid attrs and rels", %{ conn: conn, sat1: sat1 } do
      conn = put_req_header(conn, "authorization", "Bearer #{sat1}")

      conn = post(conn, "/v1/customers", %{
        "data" => %{
          "type" => "Customer",
          "attributes" => @valid_attrs
        }
      })

      assert json_response(conn, 201)["data"]["id"]
      assert json_response(conn, 201)["data"]["attributes"]["status"] == @valid_attrs["status"]
      assert json_response(conn, 201)["data"]["attributes"]["firstName"] == @valid_attrs["firstName"]
      assert json_response(conn, 201)["data"]["attributes"]["lastName"] == @valid_attrs["lastName"]
      assert json_response(conn, 201)["data"]["relationships"]["refreshToken"]["data"]["id"]
    end
  end

  describe "GET /v1/customers/:id" do
    test "with no access token", %{ conn: conn } do
      conn = get(conn, "/v1/customers/test")

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

      customer = Repo.insert!(%Customer{
        account_id: account2_id
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      assert_error_sent(404, fn ->
        get(conn, "/v1/customers/#{customer.id}")
      end)
    end

    test "with valid access token and id", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      customer = Repo.insert!(%Customer{
        account_id: account1_id
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/customers/#{customer.id}")

      assert json_response(conn, 200)["data"]["id"] == customer.id
    end

    test "with valid access token, id and locale", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      customer = Repo.insert!(%Customer{
        account_id: account1_id,
        custom_data: %{
          "kind" => "Blue Jay"
        },
        translations: %{
          "zh-CN" => %{
            "custom_data" => %{
              "kind" => "冠蓝鸟"
            }
          }
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/customers/#{customer.id}?locale=zh-CN")

      assert json_response(conn, 200)["data"]["id"] == customer.id
      assert json_response(conn, 200)["data"]["attributes"]["customData"]["kind"] == "冠蓝鸟"
    end
  end

  describe "GET /v1/customer" do
    test "with valid access token, id and locale", %{ conn: conn, account1_id: account1_id } do
      customer = Repo.insert!(%Customer{
        account_id: account1_id,
        custom_data: %{
          "kind" => "Blue Jay"
        },
        translations: %{
          "zh-CN" => %{
            "custom_data" => %{
              "kind" => "冠蓝鸟"
            }
          }
        }
      })

      refresh_token = Repo.insert!(%RefreshToken{
        account_id: account1_id,
        customer_id: customer.id
      })

      {:ok, %{ access_token: cat1 }} = Authentication.get_token(%{ refresh_token: refresh_token.id })
      conn = put_req_header(conn, "authorization", "Bearer #{cat1}")

      conn = get(conn, "/v1/customers/#{customer.id}?locale=zh-CN")

      assert json_response(conn, 200)["data"]["id"] == customer.id
      assert json_response(conn, 200)["data"]["attributes"]["customData"]["kind"] == "冠蓝鸟"
    end
  end

  describe "PATCH /v1/customers/:id" do
    test "with no access token", %{ conn: conn } do
      conn = patch(conn, "/v1/customers/test", %{
        "data" => %{
          "id" => "test",
          "type" => "Customer",
          "attributes" => @valid_attrs
        }
      })

      assert conn.status == 401
    end

    test "with access token of a different account", %{ conn: conn, account1_id: account1_id } do
      customer1 = Repo.insert!(%Customer{
        account_id: account1_id
      })
      refresh_token = Repo.insert!(%RefreshToken{
        account_id: account1_id,
        customer_id: customer1.id
      })
      {:ok, %{ access_token: cat1 }} = Authentication.get_token(%{ refresh_token: refresh_token.id })

      customer2 = Repo.insert!(%Customer{
        account_id: account1_id
      })

      conn = put_req_header(conn, "authorization", "Bearer #{cat1}")

      assert_error_sent(404, fn ->
        patch(conn, "/v1/customers/#{customer2.id}", %{
          "data" => %{
            "id" => customer2.id,
            "type" => "Customer",
            "attributes" => @valid_attrs
          }
        })
      end)
    end

    test "with valid access token, invalid attrs and rels", %{ conn: conn, account1_id: account1_id } do
      customer1 = Repo.insert!(%Customer{
        account_id: account1_id
      })
      refresh_token = Repo.insert!(%RefreshToken{
        account_id: account1_id,
        customer_id: customer1.id
      })
      {:ok, %{ access_token: cat1 }} = Authentication.get_token(%{ refresh_token: refresh_token.id })

      conn = put_req_header(conn, "authorization", "Bearer #{cat1}")

      conn = patch(conn, "/v1/customers/#{customer1.id}", %{
        "data" => %{
          "id" => customer1.id,
          "type" => "Customer",
          "attributes" => @invalid_attrs
        }
      })

      assert json_response(conn, 422)["errors"]
      assert length(json_response(conn, 422)["errors"]) > 0
    end

    test "with valid access token, attrs and rels", %{ conn: conn, account1_id: account1_id } do
      customer1 = Repo.insert!(%Customer{
        account_id: account1_id
      })
      refresh_token = Repo.insert!(%RefreshToken{
        account_id: account1_id,
        customer_id: customer1.id
      })
      {:ok, %{ access_token: cat1 }} = Authentication.get_token(%{ refresh_token: refresh_token.id })

      conn = put_req_header(conn, "authorization", "Bearer #{cat1}")

      conn = patch(conn, "/v1/customers/#{customer1.id}", %{
        "data" => %{
          "id" => customer1.id,
          "type" => "Customer",
          "attributes" => @valid_attrs
        }
      })

      assert json_response(conn, 200)["data"]["id"]
      assert json_response(conn, 200)["data"]["attributes"]["status"] == @valid_attrs["status"]
      assert json_response(conn, 200)["data"]["attributes"]["firstName"] == @valid_attrs["firstName"]
      assert json_response(conn, 200)["data"]["attributes"]["lastName"] == @valid_attrs["lastName"]
      assert json_response(conn, 200)["data"]["attributes"]["customData"]["kind"] == @valid_attrs["customData"]["kind"]
    end

    test "with valid access token, attrs, rels and locale", %{ conn: conn, account1_id: account1_id } do
      customer1 = Repo.insert!(%Customer{
        account_id: account1_id
      })
      refresh_token = Repo.insert!(%RefreshToken{
        account_id: account1_id,
        customer_id: customer1.id
      })
      {:ok, %{ access_token: cat1 }} = Authentication.get_token(%{ refresh_token: refresh_token.id })

      conn = put_req_header(conn, "authorization", "Bearer #{cat1}")

      conn = patch(conn, "/v1/customers/#{customer1.id}?locale=zh-CN", %{
        "data" => %{
          "id" => customer1.id,
          "type" => "Customer",
          "attributes" => @valid_attrs
        }
      })

      assert json_response(conn, 200)["data"]["id"]
      assert json_response(conn, 200)["data"]["attributes"]["status"] == @valid_attrs["status"]
      assert json_response(conn, 200)["data"]["attributes"]["firstName"] == @valid_attrs["firstName"]
      assert json_response(conn, 200)["data"]["attributes"]["lastName"] == @valid_attrs["lastName"]
      assert json_response(conn, 200)["data"]["attributes"]["customData"]["kind"] == @valid_attrs["customData"]["kind"]
    end
  end

  describe "GET /v1/customers" do
    test "with no access token", %{ conn: conn } do
      conn = get(conn, "/v1/customers")

      assert conn.status == 401
    end

    test "with valid access token", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      {_, %User{ default_account_id: account2_id }} = UserRegistration.sign_up(%{
        first_name: Faker.Name.first_name(),
        last_name: Faker.Name.last_name(),
        email: "test2@example.com",
        password: "test1234",
        account_name: Faker.Company.name()
      })

      Repo.insert!(%Customer{
        account_id: account2_id
      })
      Repo.insert!(%Customer{
        account_id: account1_id
      })
      Repo.insert!(%Customer{
        account_id: account1_id
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/customers")

      assert length(json_response(conn, 200)["data"]) == 2
      assert json_response(conn, 200)["meta"]["resultCount"] == 2
      assert json_response(conn, 200)["meta"]["totalCount"] == 2
    end

    test "with valid access token and pagination", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      Repo.insert!(%Customer{
        account_id: account1_id
      })
      Repo.insert!(%Customer{
        account_id: account1_id
      })
      Repo.insert!(%Customer{
        account_id: account1_id
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/customers?page[number]=2&page[size]=1")

      assert length(json_response(conn, 200)["data"]) == 1
      assert json_response(conn, 200)["meta"]["resultCount"] == 3
      assert json_response(conn, 200)["meta"]["totalCount"] == 3
    end

    test "with valid access token and filter", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      Repo.insert!(%Customer{
        account_id: account1_id,
        status: "member"
      })
      Repo.insert!(%Customer{
        account_id: account1_id,
        status: "member"
      })
      Repo.insert!(%Customer{
        account_id: account1_id,
        status: "guest"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/customers?filter[status]=member")

      assert length(json_response(conn, 200)["data"]) == 2
      assert json_response(conn, 200)["meta"]["resultCount"] == 2
      assert json_response(conn, 200)["meta"]["totalCount"] == 3
    end

    test "with valid access token and locale", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      Repo.insert!(%Customer{
        account_id: account1_id,
        translations: %{
          "zh-CN" => %{
            "custom_data" => %{
              "kind" => "好人"
            }
          }
        }
      })
      Repo.insert!(%Customer{
        account_id: account1_id,
        translations: %{
          "zh-CN" => %{
            "custom_data" => %{
              "kind" => "好人"
            }
          }
        }
      })
      Repo.insert!(%Customer{
        account_id: account1_id,
        translations: %{
          "zh-CN" => %{
            "custom_data" => %{
              "kind" => "好人"
            }
          }
        }
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/customers?locale=zh-CN")

      assert length(json_response(conn, 200)["data"]) == 3
      assert json_response(conn, 200)["meta"]["resultCount"] == 3
      assert json_response(conn, 200)["meta"]["totalCount"] == 3
      assert length(Enum.filter(json_response(conn, 200)["data"], fn(item) -> item["attributes"]["customData"]["kind"] == "好人" end)) == 3
    end

    test "with valid access token and search", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      {_, %User{ default_account_id: account2_id }} = UserRegistration.sign_up(%{
        first_name: Faker.Name.first_name(),
        last_name: Faker.Name.last_name(),
        email: "test2@example.com",
        password: "test1234",
        account_name: Faker.Company.name()
      })

      Repo.insert!(%Customer{
        account_id: account2_id,
        first_name: "毛主席"
      })
      Repo.insert!(%Customer{
        account_id: account1_id,
        first_name: "毛主席"
      })
      Repo.insert!(%Customer{
        account_id: account1_id,
        first_name: "毛主席"
      })
      Repo.insert!(%Customer{
        account_id: account1_id
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, "/v1/customers?search=毛")

      assert length(json_response(conn, 200)["data"]) == 2
      assert json_response(conn, 200)["meta"]["resultCount"] == 2
      assert json_response(conn, 200)["meta"]["totalCount"] == 3
    end
  end

  describe "DELETE /v1/customers/:id" do
    test "with no access token", %{ conn: conn } do
      conn = delete(conn, "/v1/customers/test")

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

      customer = Repo.insert!(%Customer{
        account_id: account2_id
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      assert_error_sent(404, fn ->
        delete(conn, "/v1/customers/#{customer.id}")
      end)
    end

    test "with valid access token and id", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      customer = Repo.insert!(%Customer{
        account_id: account1_id
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = delete(conn, "/v1/customers/#{customer.id}")

      assert conn.status == 204
    end
  end
end
