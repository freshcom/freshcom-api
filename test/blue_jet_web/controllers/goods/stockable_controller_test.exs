defmodule BlueJetWeb.StockableControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper

  alias BlueJet.Goods

  def create_stockable(user) do
    {:ok, %{data: stockable}} = Goods.create_stockable(%CreateRequest{
      fields: %{
        "name" => Faker.Commerce.product_name(),
        "unit_of_measure" => "EA"
      },
      vas: %{account_id: user.default_account_id, user_id: user.id}
    })

    stockable
  end

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{ conn: conn }
  end

  # Create a stockable
  describe "POST /v1/stockables" do
    test "without access token", %{conn: conn} do
      conn = post(conn, "/v1/stockables", %{
        "data" => %{
          "type" => "Stockable"
        }
      })

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      standard_user = create_standard_user()
      pat = get_pat(standard_user)
      conn = put_req_header(conn, "authorization", "Bearer #{pat}")

      conn = post(conn, "/v1/stockables", %{
        "data" => %{
          "type" => "Stockable"
        }
      })

      assert conn.status == 403
    end

    test "with no attributes", %{conn: conn} do
      standard_user = create_standard_user()
      uat = get_uat(standard_user)
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = post(conn, "/v1/stockables", %{
        "data" => %{
          "type" => "Stockable"
        }
      })

      response = json_response(conn, 422)
      assert length(response["errors"]) == 2
    end

    test "with valid attributes", %{conn: conn} do
      standard_user = create_standard_user()
      uat = get_uat(standard_user)
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = post(conn, "/v1/stockables", %{
        "data" => %{
          "type" => "Stockable",
          "attributes" => %{
            "name" => Faker.Commerce.product_name(),
            "unit_of_measure" => "EA"
          }
        }
      })

      assert json_response(conn, 201)
    end
  end

  # Retrieve a stockable
  describe "GET /v1/stockables/:id" do
    test "without access token", %{conn: conn} do
      conn = get(conn, "/v1/stockables/#{Ecto.UUID.generate()}")

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      standard_user = create_standard_user()
      pat = get_pat(standard_user)
      conn = put_req_header(conn, "authorization", "Bearer #{pat}")

      conn = get(conn, "/v1/stockables/#{Ecto.UUID.generate()}")

      assert conn.status == 403
    end

    test "with UAT requesting a stockable of a different account", %{conn: conn} do
      standard_user1 = create_standard_user()
      standard_user2 = create_standard_user(n: 2)

      stockable = create_stockable(standard_user2)

      uat = get_uat(standard_user1)
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = get(conn, "/v1/stockables/#{stockable.id}")

      assert conn.status == 404
    end

    test "with UAT", %{conn: conn} do
      standard_user = create_standard_user()
      stockable = create_stockable(standard_user)

      uat = get_uat(standard_user)
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = get(conn, "/v1/stockables/#{stockable.id}")

      assert json_response(conn, 200)
    end
  end

  # Update a stockable
  describe "PATCH /v1/stockables/:id" do
    test "without access token", %{conn: conn} do
      conn = patch(conn, "/v1/stockables/#{Ecto.UUID.generate()}", %{
        "data" => %{
          "type" => "Stockable",
          "attributes" => %{
            "name" => Faker.Commerce.product_name()
          }
        }
      })

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      standard_user = create_standard_user()
      pat = get_pat(standard_user)
      conn = put_req_header(conn, "authorization", "Bearer #{pat}")

      conn = patch(conn, "/v1/stockables/#{Ecto.UUID.generate()}", %{
        "data" => %{
          "type" => "Stockable",
          "attributes" => %{
            "name" => Faker.Commerce.product_name()
          }
        }
      })

      assert conn.status == 403
    end

    test "with UAT requesting stockable of a different account", %{conn: conn} do
      standard_user1 = create_standard_user()
      standard_user2 = create_standard_user(n: 2)

      stockable = create_stockable(standard_user2)

      uat = get_uat(standard_user1)
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = patch(conn, "/v1/stockables/#{stockable.id}", %{
        "data" => %{
          "type" => "Stockable",
          "attributes" => %{
            "name" => Faker.Commerce.product_name()
          }
        }
      })

      assert conn.status == 404
    end

    test "with UAT", %{conn: conn} do
      standard_user = create_standard_user()
      stockable = create_stockable(standard_user)

      uat = get_uat(standard_user)
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = patch(conn, "/v1/stockables/#{stockable.id}", %{
        "data" => %{
          "type" => "Stockable",
          "attributes" => %{
            "name" => Faker.Commerce.product_name()
          }
        }
      })

      assert json_response(conn, 200)
    end
  end

  # Delete a stockable
  describe "DELETE /v1/stockables/:id" do
    test "without access token", %{conn: conn} do
      conn = delete(conn, "/v1/stockables/#{Ecto.UUID.generate()}")

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      standard_user = create_standard_user()
      pat = get_pat(standard_user)
      conn = put_req_header(conn, "authorization", "Bearer #{pat}")

      conn = delete(conn, "/v1/stockables/#{Ecto.UUID.generate()}")

      assert conn.status == 403
    end

    test "with UAT and requesting stockable of a different account", %{conn: conn} do
      standard_user1 = create_standard_user()
      standard_user2 = create_standard_user(n: 2)

      stockable = create_stockable(standard_user2)

      uat = get_uat(standard_user1)
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = delete(conn, "/v1/stockables/#{stockable.id}")

      assert conn.status == 404
    end

    test "with UAT", %{conn: conn} do
      standard_user = create_standard_user()
      stockable = create_stockable(standard_user)

      uat = get_uat(standard_user)
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = delete(conn, "/v1/stockables/#{stockable.id}")

      assert conn.status == 204
    end
  end

  # List stockable
  describe "GET /v1/stockables" do
    test "without UAT", %{conn: conn} do
      conn = get(conn, "/v1/stockables")

      assert conn.status == 401
    end

    test "with UAT", %{conn: conn} do
      standard_user1 = create_standard_user()
      standard_user2 = create_standard_user(n: 2)

      create_stockable(standard_user1)
      create_stockable(standard_user1)
      create_stockable(standard_user2)

      uat = get_uat(standard_user1)
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = get(conn, "/v1/stockables")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2
    end
  end
end
