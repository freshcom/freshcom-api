defmodule BlueJetWeb.CardControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper
  import BlueJet.CRM.TestHelper
  import BlueJet.Balance.TestHelper
  import BlueJet.Stripe.TestHelper

  alias BlueJet.Balance.Card

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{conn: conn}
  end

  # Create a card
  describe "POST /v1/cards" do
    test "without access token", %{conn: conn} do
      conn = post(conn, "/v1/cards", %{
        "data" => %{
          "type" => "Card"
        }
      })

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      user = standard_user_fixture()
      pat = get_pat(user.default_account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = post(conn, "/v1/cards", %{
        "data" => %{
          "type" => "Card"
        }
      })

      assert conn.status == 403
    end

    test "with no attributes", %{conn: conn} do
      user = standard_user_fixture()
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/cards", %{
        "data" => %{
          "type" => "Card"
        }
      })

      response = json_response(conn, 422)
      assert length(response["errors"]) == 3
    end

    @tag :hits_external_service
    test "with valid attributes", %{conn: conn} do
      user = standard_user_fixture()
      uat = get_uat(user.default_account.test_account, user)
      customer = customer_fixture(user.default_account.test_account)
      stripe_token = stripe_token_fixture()
      token = stripe_token["id"]

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/cards", %{
        "data" => %{
          "type" => "Card",
          "attributes" => %{
            "source" => token
          },
          "relationships" => %{
            "owner" => %{
              "data" => %{
                "id" => customer.id,
                "type" => "Customer"
              }
            }
          }
        }
      })

      response = json_response(conn, 201)
      assert response

      card = Repo.get(Card, response["data"]["id"])
      delete_stripe_customer(card.stripe_customer_id)
    end
  end

  # Retrieve a card
  describe "GET /v1/cards/:id" do
    test "without access token", %{conn: conn} do
      conn = get(conn, "/v1/cards/#{UUID.generate()}")

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      user = standard_user_fixture()
      pat = get_pat(user.default_account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = get(conn, "/v1/cards/#{UUID.generate()}")

      assert conn.status == 403
    end

    test "with UAT requesting a card of a different account", %{conn: conn} do
      user1 = standard_user_fixture()
      user2 = standard_user_fixture()
      card = card_fixture(user2.default_account)
      uat = get_uat(user1.default_account, user1)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/cards/#{card.id}")

      assert conn.status == 404
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      card = card_fixture(user.default_account)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/cards/#{card.id}")

      assert json_response(conn, 200)
    end
  end

  # # Update a card
  # describe "PATCH /v1/cards/:id" do
  #   test "without access token", %{conn: conn} do
  #     conn = patch(conn, "/v1/cards/#{UUID.generate()}", %{
  #       "data" => %{
  #         "type" => "Card",
  #         "attributes" => %{
  #           "name" => Faker.Commerce.product_name()
  #         }
  #       }
  #     })

  #     assert conn.status == 401
  #   end

  #   test "with PAT", %{conn: conn} do
  #     user = standard_user_fixture()
  #     pat = get_pat(user.default_account)

  #     conn = put_req_header(conn, "authorization", "Bearer #{pat}")
  #     conn = patch(conn, "/v1/cards/#{UUID.generate()}", %{
  #       "data" => %{
  #         "type" => "Card",
  #         "attributes" => %{
  #           "name" => Faker.Commerce.product_name()
  #         }
  #       }
  #     })

  #     assert conn.status == 403
  #   end

  #   test "with UAT requesting card of a different account", %{conn: conn} do
  #     user1 = standard_user_fixture()
  #     user2 = standard_user_fixture()
  #     card = card_fixture(user2.default_account)
  #     uat = get_uat(user1.default_account, user1)

  #     conn = put_req_header(conn, "authorization", "Bearer #{uat}")
  #     conn = patch(conn, "/v1/cards/#{card.id}", %{
  #       "data" => %{
  #         "type" => "Card",
  #         "attributes" => %{
  #           "name" => Faker.Commerce.product_name()
  #         }
  #       }
  #     })

  #     assert conn.status == 404
  #   end

  #   test "with UAT", %{conn: conn} do
  #     user = standard_user_fixture()
  #     card = card_fixture(user.default_account)
  #     uat = get_uat(user.default_account, user)

  #     conn = put_req_header(conn, "authorization", "Bearer #{uat}")
  #     conn = patch(conn, "/v1/cards/#{card.id}", %{
  #       "data" => %{
  #         "type" => "Card",
  #         "attributes" => %{
  #           "name" => Faker.Commerce.product_name()
  #         }
  #       }
  #     })

  #     assert json_response(conn, 200)
  #   end
  # end

  # # Delete a card
  # describe "DELETE /v1/cards/:id" do
  #   test "without access token", %{conn: conn} do
  #     conn = delete(conn, "/v1/cards/#{UUID.generate()}")

  #     assert conn.status == 401
  #   end

  #   test "with PAT", %{conn: conn} do
  #     user = standard_user_fixture()
  #     pat = get_pat(user.default_account)

  #     conn = put_req_header(conn, "authorization", "Bearer #{pat}")
  #     conn = delete(conn, "/v1/cards/#{UUID.generate()}")

  #     assert conn.status == 403
  #   end

  #   test "with UAT and requesting card of a different account", %{conn: conn} do
  #     user1 = standard_user_fixture()
  #     user2 = standard_user_fixture()
  #     card = card_fixture(user2.default_account)
  #     uat = get_uat(user1.default_account, user1)

  #     conn = put_req_header(conn, "authorization", "Bearer #{uat}")
  #     conn = delete(conn, "/v1/cards/#{card.id}")

  #     assert conn.status == 404
  #   end

  #   test "with UAT", %{conn: conn} do
  #     user = standard_user_fixture()
  #     card = card_fixture(user.default_account)
  #     uat = get_uat(user.default_account, user)

  #     conn = put_req_header(conn, "authorization", "Bearer #{uat}")
  #     conn = delete(conn, "/v1/cards/#{card.id}")

  #     assert conn.status == 204
  #   end
  # end

  # # List card
  # describe "GET /v1/cards" do
  #   test "without access token", %{conn: conn} do
  #     conn = get(conn, "/v1/cards")

  #     assert conn.status == 401
  #   end

  #   test "with UAT", %{conn: conn} do
  #     user1 = standard_user_fixture()
  #     user2 = standard_user_fixture()

  #     card_fixture(user1.default_account)
  #     card_fixture(user1.default_account)
  #     card_fixture(user2.default_account)

  #     uat = get_uat(user1.default_account, user1)

  #     conn = put_req_header(conn, "authorization", "Bearer #{uat}")
  #     conn = get(conn, "/v1/cards")

  #     response = json_response(conn, 200)
  #     assert length(response["data"]) == 2
  #   end
  # end
end
