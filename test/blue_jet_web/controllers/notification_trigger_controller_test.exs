defmodule BlueJetWeb.NotificationTriggerControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper

  alias BlueJet.AccessRequest
  alias BlueJet.Notification

  setup do
    conn = build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{ conn: conn }
  end

  describe "GET /v1/notification_triggers" do
    test "with no access token", %{ conn: conn } do
      conn = get(conn, "/v1/notification_triggers")

      assert conn.status == 401
    end

    test "with a valid request", %{ conn: conn } do
      %{ user: user } = create_global_identity("administrator")
      uat = create_access_token(user.username, "test1234")
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = get(conn, "/v1/notification_triggers")

      assert conn.status == 200
    end
  end

  describe "POST /v1/notification_triggers" do
    test "with no access token", %{ conn: conn } do
      conn = post(conn, "/v1/notification_triggers", %{
        "data" => %{
          "type" => "NotificationTrigger",
          "attributes" => %{
            "name" => "Password Reset Email Trigger"
          }
        }
      })

      assert conn.status == 401
    end

    test "with a valid request", %{ conn: conn } do
      %{ user: user } = create_global_identity("administrator")
      uat = create_access_token(user.username, "test1234")
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = post(conn, "/v1/notification_triggers", %{
        "data" => %{
          "type" => "NotificationTrigger",
          "attributes" => %{
            "name" => "Password Reset Email Trigger",
            "eventId" => "password_reset_token.created"
          },
          "relationships" => %{
            "target": %{
              "data": %{
                "id": Ecto.UUID.generate(),
                "type": "EmailTemplate"
              }
            }
          }
        }
      })

      assert conn.status == 201
    end
  end

  # describe "GET /v1/notification_triggers/:id" do
  #   test "with no access token", %{ conn: conn } do
  #     conn = get(conn, "/v1/notification_triggers/invalid")

  #     assert conn.status == 401
  #   end

  #   test "with a valid request", %{ conn: conn } do
  #     %{ user: user, account: account } = create_global_identity("administrator")
  #     {:ok, %{ data: notification_trigger }} = Notification.do_create_notification_trigger(%AccessRequest{
  #       account: account,
  #       fields: %{
  #         "name" => "Email Verification",
  #         "content" => "<html></html>"
  #       }
  #     })

  #     uat = create_access_token(user.username, "test1234")
  #     conn = put_req_header(conn, "authorization", "Bearer #{uat}")

  #     conn = get(conn, "/v1/notification_triggers/#{notification_trigger.id}")

  #     assert conn.status == 200
  #     assert json_response(conn, 200)["data"]["id"] == notification_trigger.id
  #     assert json_response(conn, 200)["data"]["attributes"]["name"] == "Email Verification"
  #   end
  # end

  # describe "PATCH /v1/notification_triggers/:id" do
  #   test "with no access token", %{ conn: conn } do
  #     conn = patch(conn, "/v1/notification_triggers/invalid", %{
  #       "data" => %{
  #         "id" => "invalid",
  #         "type" => "NotificationTrigger",
  #         "attributes" => %{
  #           "name" => "invalid"
  #         }
  #       }
  #     })

  #     assert conn.status == 401
  #   end

  #   test "with a valid request", %{ conn: conn } do
  #     %{ user: user, account: account } = create_global_identity("administrator")
  #     {:ok, %{ data: notification_trigger }} = Notification.do_create_notification_trigger(%AccessRequest{
  #       account: account,
  #       fields: %{
  #         "name" => "Email Verification",
  #         "content" => "<html></html>"
  #       }
  #     })

  #     uat = create_access_token(user.username, "test1234")
  #     conn = put_req_header(conn, "authorization", "Bearer #{uat}")

  #     conn = patch(conn, "/v1/notification_triggers/#{notification_trigger.id}", %{
  #       "data" => %{
  #         "id" => notification_trigger.id,
  #         "type" => "NotificationTrigger",
  #         "attributes" => %{
  #           "name" => "Welcome"
  #         }
  #       }
  #     })

  #     assert conn.status == 200
  #     assert json_response(conn, 200)["data"]["id"] == notification_trigger.id
  #     assert json_response(conn, 200)["data"]["attributes"]["name"] == "Welcome"
  #   end
  # end

  # describe "DELETE /v1/notification_triggers/:id" do
  #   test "with no access token", %{ conn: conn } do
  #     conn = delete(conn, "/v1/notification_triggers/invalid")

  #     assert conn.status == 401
  #   end

  #   test "with a valid request", %{ conn: conn } do
  #     %{ user: user, account: account } = create_global_identity("administrator")
  #     {:ok, %{ data: notification_trigger }} = Notification.do_create_notification_trigger(%AccessRequest{
  #       account: account,
  #       fields: %{
  #         "name" => "Email Verification",
  #         "content" => "<html></html>"
  #       }
  #     })

  #     uat = create_access_token(user.username, "test1234")
  #     conn = put_req_header(conn, "authorization", "Bearer #{uat}")

  #     conn = delete(conn, "/v1/notification_triggers/#{notification_trigger.id}")

  #     assert conn.status == 204
  #   end
  # end
end
