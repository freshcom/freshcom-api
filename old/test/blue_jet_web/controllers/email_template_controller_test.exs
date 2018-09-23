defmodule BlueJetWeb.EmailTemplateControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper

  alias BlueJet.ContextRequest
  alias BlueJet.Notification

  setup do
    conn = build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{conn: conn}
  end

  describe "GET /v1/email_templates" do
    test "with no access token", %{conn: conn} do
      conn = get(conn, "/v1/email_templates")

      assert conn.status == 401
    end

    test "with a valid request", %{conn: conn} do
      %{ user: user } = create_global_identity("administrator")
      uat = create_access_token(user.username, "test1234")
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = get(conn, "/v1/email_templates")

      assert conn.status == 200
    end
  end

  describe "POST /v1/email_templates" do
    test "with no access token", %{conn: conn} do
      conn = post(conn, "/v1/email_templates", %{
        "data" => %{
          "type" => "EmailTemplate",
          "attributes" => %{
            "content" => "<html></html>"
          }
        }
      })

      assert conn.status == 401
    end

    test "with a valid request", %{conn: conn} do
      %{ user: user } = create_global_identity("administrator")
      uat = create_access_token(user.username, "test1234")
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = post(conn, "/v1/email_templates", %{
        "data" => %{
          "type" => "EmailTemplate",
          "attributes" => %{
            "name" => "Email Verification",
            "content" => "<html></html>"
          }
        }
      })

      assert conn.status == 201
    end
  end

  describe "GET /v1/email_templates/:id" do
    test "with no access token", %{conn: conn} do
      conn = get(conn, "/v1/email_templates/invalid")

      assert conn.status == 401
    end

    test "with a valid request", %{conn: conn} do
      %{ user: user, account: account } = create_global_identity("administrator")
      {:ok, %{ data: email_template }} = Notification.do_create_email_template(%ContextRequest{
        account: account,
        fields: %{
          "name" => "Email Verification",
          "content" => "<html></html>"
        }
      })

      uat = create_access_token(user.username, "test1234")
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = get(conn, "/v1/email_templates/#{email_template.id}")

      assert conn.status == 200
      assert json_response(conn, 200)["data"]["id"] == email_template.id
      assert json_response(conn, 200)["data"]["attributes"]["name"] == "Email Verification"
    end
  end

  describe "PATCH /v1/email_templates/:id" do
    test "with no access token", %{conn: conn} do
      conn = patch(conn, "/v1/email_templates/invalid", %{
        "data" => %{
          "id" => "invalid",
          "type" => "EmailTemplate",
          "attributes" => %{
            "name" => "invalid"
          }
        }
      })

      assert conn.status == 401
    end

    test "with a valid request", %{conn: conn} do
      %{ user: user, account: account } = create_global_identity("administrator")
      {:ok, %{ data: email_template }} = Notification.do_create_email_template(%ContextRequest{
        account: account,
        fields: %{
          "name" => "Email Verification",
          "content" => "<html></html>"
        }
      })

      uat = create_access_token(user.username, "test1234")
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = patch(conn, "/v1/email_templates/#{email_template.id}", %{
        "data" => %{
          "id" => email_template.id,
          "type" => "EmailTemplate",
          "attributes" => %{
            "name" => "Welcome"
          }
        }
      })

      assert conn.status == 200
      assert json_response(conn, 200)["data"]["id"] == email_template.id
      assert json_response(conn, 200)["data"]["attributes"]["name"] == "Welcome"
    end
  end

  describe "DELETE /v1/email_templates/:id" do
    test "with no access token", %{conn: conn} do
      conn = delete(conn, "/v1/email_templates/invalid")

      assert conn.status == 401
    end

    test "with a valid request", %{conn: conn} do
      %{ user: user, account: account } = create_global_identity("administrator")
      {:ok, %{ data: email_template }} = Notification.do_create_email_template(%ContextRequest{
        account: account,
        fields: %{
          "name" => "Email Verification",
          "content" => "<html></html>"
        }
      })

      uat = create_access_token(user.username, "test1234")
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")

      conn = delete(conn, "/v1/email_templates/#{email_template.id}")

      assert conn.status == 204
    end
  end
end
