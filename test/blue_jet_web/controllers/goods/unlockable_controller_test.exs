defmodule BlueJetWeb.UnlockableControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper
  import BlueJet.Goods.TestHelper

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{conn: conn}
  end

  # Create a unlockable
  describe "POST /v1/unlockables" do
    test "without access token", %{conn: conn} do
      conn = post(conn, "/v1/unlockables", %{
        "data" => %{
          "type" => "Unlockable"
        }
      })

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      user = standard_user_fixture()
      pat = get_pat(user.default_account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = post(conn, "/v1/unlockables", %{
        "data" => %{
          "type" => "Unlockable"
        }
      })

      assert conn.status == 403
    end

    test "with no attributes", %{conn: conn} do
      user = standard_user_fixture()
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/unlockables", %{
        "data" => %{
          "type" => "Unlockable"
        }
      })

      response = json_response(conn, 422)
      assert length(response["errors"]) == 1
    end

    test "with valid attributes", %{conn: conn} do
      user = standard_user_fixture()
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/unlockables", %{
        "data" => %{
          "type" => "Unlockable",
          "attributes" => %{
            "name" => Faker.Commerce.product_name()
          }
        }
      })

      assert json_response(conn, 201)
    end
  end

  # Retrieve a unlockable
  describe "GET /v1/unlockables/:id" do
    test "without access token", %{conn: conn} do
      conn = get(conn, "/v1/unlockables/#{UUID.generate()}")

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      user = standard_user_fixture()
      pat = get_pat(user.default_account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = get(conn, "/v1/unlockables/#{UUID.generate()}")

      assert conn.status == 403
    end

    test "with UAT requesting a unlockable of a different account", %{conn: conn} do
      user1 = standard_user_fixture()
      user2 = standard_user_fixture()
      unlockable = unlockable_fixture(user2.default_account)
      uat = get_uat(user1.default_account, user1)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/unlockables/#{unlockable.id}")

      assert conn.status == 404
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      unlockable = unlockable_fixture(user.default_account)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/unlockables/#{unlockable.id}")

      assert json_response(conn, 200)
    end
  end

  # Update a unlockable
  describe "PATCH /v1/unlockables/:id" do
    test "without access token", %{conn: conn} do
      conn = patch(conn, "/v1/unlockables/#{UUID.generate()}", %{
        "data" => %{
          "type" => "Unlockable",
          "attributes" => %{
            "name" => Faker.Commerce.product_name()
          }
        }
      })

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      user = standard_user_fixture()
      pat = get_pat(user.default_account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = patch(conn, "/v1/unlockables/#{UUID.generate()}", %{
        "data" => %{
          "type" => "Unlockable",
          "attributes" => %{
            "name" => Faker.Commerce.product_name()
          }
        }
      })

      assert conn.status == 403
    end

    test "with UAT requesting unlockable of a different account", %{conn: conn} do
      user1 = standard_user_fixture()
      user2 = standard_user_fixture()
      unlockable = unlockable_fixture(user2.default_account)
      uat = get_uat(user1.default_account, user1)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/unlockables/#{unlockable.id}", %{
        "data" => %{
          "type" => "Unlockable",
          "attributes" => %{
            "name" => Faker.Commerce.product_name()
          }
        }
      })

      assert conn.status == 404
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      unlockable = unlockable_fixture(user.default_account)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/unlockables/#{unlockable.id}", %{
        "data" => %{
          "type" => "Unlockable",
          "attributes" => %{
            "name" => Faker.Commerce.product_name()
          }
        }
      })

      assert json_response(conn, 200)
    end
  end

  # Delete a unlockable
  describe "DELETE /v1/unlockables/:id" do
    test "without access token", %{conn: conn} do
      conn = delete(conn, "/v1/unlockables/#{UUID.generate()}")

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      user = standard_user_fixture()
      pat = get_pat(user.default_account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = delete(conn, "/v1/unlockables/#{UUID.generate()}")

      assert conn.status == 403
    end

    test "with UAT and requesting unlockable of a different account", %{conn: conn} do
      user1 = standard_user_fixture()
      user2 = standard_user_fixture()
      unlockable = unlockable_fixture(user2.default_account)
      uat = get_uat(user1.default_account, user1)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = delete(conn, "/v1/unlockables/#{unlockable.id}")

      assert conn.status == 404
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      unlockable = unlockable_fixture(user.default_account)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = delete(conn, "/v1/unlockables/#{unlockable.id}")

      assert conn.status == 204
    end
  end

  # List unlockable
  describe "GET /v1/unlockables" do
    test "without access token", %{conn: conn} do
      conn = get(conn, "/v1/unlockables")

      assert conn.status == 401
    end

    test "with UAT", %{conn: conn} do
      user1 = standard_user_fixture()
      user2 = standard_user_fixture()

      unlockable_fixture(user1.default_account)
      unlockable_fixture(user1.default_account)
      unlockable_fixture(user2.default_account)

      uat = get_uat(user1.default_account, user1)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/unlockables")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2
    end
  end
end
