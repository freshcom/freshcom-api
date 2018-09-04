defmodule BlueJetWeb.UnlockableControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper

  alias BlueJet.Goods

  def create_unlockable(user) do
    {:ok, %{data: unlockable}} = Goods.create_unlockable(%AccessRequest{
      fields: %{
        "name" => Faker.Commerce.product_name()
      },
      vas: %{ account_id: user.default_account_id, user_id: user.id }
    })

    unlockable
  end

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{ conn: conn }
  end

  # Create a unlockable
  describe "POST /v1/unlockables" do
    test "without UAT", %{conn: conn} do
      conn = post(conn, "/v1/unlockables", %{
        "data" => %{
          "type" => "Unlockable"
        }
      })

      assert conn.status == 401
    end

    test "with no attributes", %{conn: conn} do
      standard_user = create_standard_user()
      uat = get_uat(standard_user)
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = post(conn, "/v1/unlockables", %{
        "data" => %{
          "type" => "Unlockable"
        }
      })

      response = json_response(conn, 422)
      assert length(response["errors"]) == 1
    end
  end

  # Retrieve a unlockable
  describe "GET /v1/unlockables/:id" do
    test "without UAT", %{conn: conn} do
      conn = get(conn, "/v1/unlockables/#{Ecto.UUID.generate()}")

      assert conn.status == 401
    end

    test "with UAT", %{conn: conn} do
      standard_user = create_standard_user()
      unlockable = create_unlockable(standard_user)

      uat = get_uat(standard_user)
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = get(conn, "/v1/unlockables/#{unlockable.id}", %{
        "data" => %{
          "type" => "Unlockable"
        }
      })

      assert json_response(conn, 200)
    end
  end

  # Update a unlockable
  describe "PATCH /v1/unlockables/:id" do
    test "without UAT", %{conn: conn} do
      conn = get(conn, "/v1/unlockables/#{Ecto.UUID.generate()}")

      assert conn.status == 401
    end

    test "with UAT", %{conn: conn} do
      standard_user = create_standard_user()
      unlockable = create_unlockable(standard_user)

      uat = get_uat(standard_user)
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = patch(conn, "/v1/unlockables/#{unlockable.id}", %{
        "data" => %{
          "type" => "Unlockable"
        },
        "attributes" => %{
          "name" => Faker.Commerce.product_name()
        }
      })

      assert json_response(conn, 200)
    end
  end

  # Delete a unlockable
  describe "DELETE /v1/unlockables/:id" do
    test "without UAT", %{conn: conn} do
      conn = delete(conn, "/v1/unlockables/#{Ecto.UUID.generate()}")

      assert conn.status == 401
    end

    test "with UAT", %{conn: conn} do
      standard_user = create_standard_user()
      unlockable = create_unlockable(standard_user)

      uat = get_uat(standard_user)
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = delete(conn, "/v1/unlockables/#{unlockable.id}")

      assert conn.status == 204
    end
  end

  # List unlockable
  describe "GET /v1/unlockables" do
    test "without UAT", %{conn: conn} do
      conn = get(conn, "/v1/unlockables")

      assert conn.status == 401
    end

    test "with UAT", %{conn: conn} do
      standard_user1 = create_standard_user()
      standard_user2 = create_standard_user(n: 2)

      create_unlockable(standard_user1)
      create_unlockable(standard_user1)
      create_unlockable(standard_user2)

      uat = get_uat(standard_user1)
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = get(conn, "/v1/unlockables")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2
    end
  end
end
