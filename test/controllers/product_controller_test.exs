defmodule BlueJet.ProductControllerTest do
  use BlueJet.ConnCase

  alias BlueJet.User
  alias BlueJet.UserRegistration
  alias BlueJet.Authentication

  alias BlueJet.Product
  alias BlueJet.Repo

  @valid_attrs %{
    "status" => "active",
    "name" => "Apple",
    "customData" => %{
      "kind" => "Gala"
    }
  }
  @valid_feilds %{
    status: "active",
    name: "Orange",
    custom_data: %{
      "kind" => "Blue Jay"
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

  describe "POST /v1/products" do
    test "with no access token", %{ conn: conn } do
      conn = post(conn, product_path(conn, :create), %{
        "data" => %{
          "type" => "Product",
          "attributes" => @valid_attrs
        }
      })

      assert conn.status == 401
    end

    test "with invalid attrs", %{ conn: conn, uat1: uat1 } do
      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = post(conn, product_path(conn, :create), %{
        "data" => %{
          "type" => "Product",
          "attributes" => @invalid_attrs
        }
      })

      assert json_response(conn, 422)["errors"]
      assert length(json_response(conn, 422)["errors"]) > 0
    end

    test "with valid attrs", %{ conn: conn, uat1: uat1 } do
      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = post(conn, product_path(conn, :create), %{
        "data" => %{
          "type" => "Product",
          "attributes" => @valid_attrs
        }
      })

      assert json_response(conn, 201)["data"]["id"]
      assert json_response(conn, 201)["data"]["attributes"]["status"] == @valid_attrs["status"]
      assert json_response(conn, 201)["data"]["attributes"]["name"] == @valid_attrs["name"]
      assert json_response(conn, 201)["data"]["attributes"]["customData"] == @valid_attrs["customData"]
      assert json_response(conn, 201)["data"]["attributes"]["customData"]["kind"] == @valid_attrs["customData"]["kind"]
    end
  end

  describe "GET /v1/products/:id" do
    test "with no access token", %{ conn: conn } do
      conn = get(conn, product_path(conn, :show, "test"))

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

      product = Repo.insert!(
        Map.merge(%Product{ account_id: account2_id }, @valid_feilds)
      )

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      assert_error_sent(404, fn ->
        get(conn, product_path(conn, :show, product.id))
      end)
    end

    test "with valid access token and id", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      product = Repo.insert!(
        Map.merge(%Product{ account_id: account1_id }, @valid_feilds)
      )

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, product_path(conn, :show, product.id))

      assert json_response(conn, 200)["data"]["id"] == product.id
    end
  end

  describe "PATCH /v1/products/:id" do
    test "with no access token", %{ conn: conn } do
      conn = patch(conn, product_path(conn, :update, "test"), %{
        "data" => %{
          "id" => "test",
          "type" => "Product",
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

      product = Repo.insert!(
        Map.merge(%Product{ account_id: account2_id }, @valid_feilds)
      )

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      assert_error_sent(404, fn ->
        patch(conn, product_path(conn, :update, product.id), %{
          "data" => %{
            "id" => product.id,
            "type" => "Product",
            "attributes" => @valid_attrs
          }
        })
      end)
    end

    test "with good access token but invalid attrs", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      product = Repo.insert!(
        Map.merge(%Product{ account_id: account1_id }, @valid_feilds)
      )

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = patch(conn, product_path(conn, :update, product.id), %{
        "data" => %{
          "id" => product.id,
          "type" => "Product",
          "attributes" => @invalid_attrs
        }
      })

      assert json_response(conn, 422)["errors"]
      assert length(json_response(conn, 422)["errors"]) > 0
    end

    test "with good access token and valid attrs", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      product = Repo.insert!(
        Map.merge(%Product{ account_id: account1_id }, @valid_feilds)
      )

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = patch(conn, product_path(conn, :update, product.id), %{
        "data" => %{
          "id" => product.id,
          "type" => "Product",
          "attributes" => @valid_attrs
        }
      })

      assert json_response(conn, 200)["data"]["id"]
      assert json_response(conn, 200)["data"]["attributes"]["status"] == @valid_attrs["status"]
      assert json_response(conn, 200)["data"]["attributes"]["name"] == @valid_attrs["name"]
      assert json_response(conn, 200)["data"]["attributes"]["printName"] == @valid_attrs["printName"]
      assert json_response(conn, 200)["data"]["attributes"]["unitOfMeasure"] == @valid_attrs["unitOfMeasure"]
      assert json_response(conn, 200)["data"]["attributes"]["customData"]["kind"] == @valid_attrs["customData"]["kind"]
    end
  end

  describe "GET /v1/products" do
    test "with no access token", %{ conn: conn } do
      conn = get(conn, product_path(conn, :index))

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

      Repo.insert!(
        Map.merge(%Product{ account_id: account2_id }, @valid_feilds)
      )
      Repo.insert!(
        Map.merge(%Product{ account_id: account1_id }, @valid_feilds)
      )
      Repo.insert!(
        Map.merge(%Product{ account_id: account1_id }, @valid_feilds)
      )

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, product_path(conn, :index))

      assert length(json_response(conn, 200)["data"]) == 2
    end
  end

  describe "DELETE /v1/products/:id" do
    test "with no access token", %{ conn: conn } do
      conn = delete(conn, product_path(conn, :delete, "test"))

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

      product = Repo.insert!(
        Map.merge(%Product{ account_id: account2_id }, @valid_feilds)
      )

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      assert_error_sent(404, fn ->
        delete(conn, product_path(conn, :delete, product.id))
      end)
    end

    test "with valid access token and id", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      product = Repo.insert!(
        Map.merge(%Product{ account_id: account1_id }, @valid_feilds)
      )

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = delete(conn, product_path(conn, :delete, product.id))

      assert conn.status == 204
    end
  end
end
