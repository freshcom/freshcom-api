defmodule BlueJetWeb.DepositableControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper

  alias BlueJet.Goods

  def create_depositable(user) do
    {:ok, %{data: depositable}} = Goods.create_depositable(%AccessRequest{
      fields: %{
        "name" => Faker.Commerce.product_name(),
        "amount" => 5000,
        "gateway" => "freshcom"
      },
      vas: %{ account_id: user.default_account_id, user_id: user.id }
    })

    depositable
  end

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{ conn: conn }
  end

  # Create a depositable
  describe "POST /v1/depositables" do
    test "without UAT", %{conn: conn} do
      conn = post(conn, "/v1/depositables", %{
        "data" => %{
          "type" => "Depositable"
        }
      })

      assert conn.status == 401
    end

    test "with no attributes", %{conn: conn} do
      standard_user = create_standard_user()
      uat = get_uat(standard_user)
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = post(conn, "/v1/depositables", %{
        "data" => %{
          "type" => "Depositable"
        }
      })

      response = json_response(conn, 422)
      assert length(response["errors"]) == 3
    end
  end

  # Retrieve a depositable
  describe "GET /v1/depositables/:id" do
    test "without UAT", %{conn: conn} do
      conn = get(conn, "/v1/depositables/#{Ecto.UUID.generate()}")

      assert conn.status == 401
    end

    test "with UAT", %{conn: conn} do
      standard_user = create_standard_user()
      depositable = create_depositable(standard_user)

      uat = get_uat(standard_user)
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = get(conn, "/v1/depositables/#{depositable.id}", %{
        "data" => %{
          "type" => "Depositable"
        }
      })

      assert json_response(conn, 200)
    end
  end

  # Update a depositable
  describe "PATCH /v1/depositables/:id" do
    test "without UAT", %{conn: conn} do
      conn = get(conn, "/v1/depositables/#{Ecto.UUID.generate()}")

      assert conn.status == 401
    end

    test "with UAT", %{conn: conn} do
      standard_user = create_standard_user()
      depositable = create_depositable(standard_user)

      uat = get_uat(standard_user)
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = patch(conn, "/v1/depositables/#{depositable.id}", %{
        "data" => %{
          "type" => "Depositable"
        },
        "attributes" => %{
          "name" => Faker.Commerce.product_name()
        }
      })

      assert json_response(conn, 200)
    end
  end

  # Delete a depositable
  describe "DELETE /v1/depositables/:id" do
    test "without UAT", %{conn: conn} do
      conn = delete(conn, "/v1/depositables/#{Ecto.UUID.generate()}")

      assert conn.status == 401
    end

    test "with UAT", %{conn: conn} do
      standard_user = create_standard_user()
      depositable = create_depositable(standard_user)

      uat = get_uat(standard_user)
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = delete(conn, "/v1/depositables/#{depositable.id}")

      assert conn.status == 204
    end
  end

  # List depositable
  describe "GET /v1/depositables" do
    test "without UAT", %{conn: conn} do
      conn = get(conn, "/v1/depositables")

      assert conn.status == 401
    end

    test "with UAT", %{conn: conn} do
      standard_user1 = create_standard_user()
      standard_user2 = create_standard_user(n: 2)

      create_depositable(standard_user1)
      create_depositable(standard_user1)
      create_depositable(standard_user2)

      uat = get_uat(standard_user1)
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = get(conn, "/v1/depositables")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2
    end
  end
end
