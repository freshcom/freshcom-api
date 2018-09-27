defmodule BlueJetWeb.EmailTemplateControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper
  import BlueJet.Notification.TestHelper

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{conn: conn}
  end

  # Create a email template
  describe "POST /v1/email_templates" do
    test "without access token", %{conn: conn} do
      conn = post(conn, "/v1/email_templates", %{
        "data" => %{
          "type" => "EmailTemplate"
        }
      })

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      user = standard_user_fixture()
      pat = get_pat(user.default_account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = post(conn, "/v1/email_templates", %{
        "data" => %{
          "type" => "EmailTemplate"
        }
      })

      assert conn.status == 403
    end

    test "with no attributes", %{conn: conn} do
      user = standard_user_fixture()
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/email_templates", %{
        "data" => %{
          "type" => "EmailTemplate"
        }
      })

      response = json_response(conn, 422)
      assert length(response["errors"]) == 4
    end

    test "with valid attributes", %{conn: conn} do
      user = standard_user_fixture()
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/email_templates", %{
        "data" => %{
          "type" => "EmailTemplate",
          "attributes" => %{
            "name" => Faker.Lorem.sentence(5),
            "to" => "{{user.email}}",
            "subject" => Faker.Lorem.sentence(5),
            "body_html" => Faker.Lorem.sentence(5),
            "body_text" => Faker.Lorem.sentence(5)
          }
        }
      })

      assert json_response(conn, 201)
    end
  end

  # Retrieve a email template
  describe "GET /v1/email_templates/:id" do
    test "without access token", %{conn: conn} do
      conn = get(conn, "/v1/email_templates/#{UUID.generate()}")

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      user = standard_user_fixture()
      pat = get_pat(user.default_account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = get(conn, "/v1/email_templates/#{UUID.generate()}")

      assert conn.status == 403
    end

    test "with UAT requesting a email_template of a different account", %{conn: conn} do
      user1 = standard_user_fixture()
      user2 = standard_user_fixture()
      email_template = email_template_fixture(user2.default_account)
      uat = get_uat(user1.default_account, user1)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/email_templates/#{email_template.id}")

      assert conn.status == 404
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      email_template = email_template_fixture(user.default_account)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/email_templates/#{email_template.id}")

      assert json_response(conn, 200)
    end
  end

  # Update a email template
  describe "PATCH /v1/email_templates/:id" do
    test "without access token", %{conn: conn} do
      conn = patch(conn, "/v1/email_templates/#{UUID.generate()}", %{
        "data" => %{
          "type" => "EmailTemplate",
          "attributes" => %{
            "name" => Faker.Lorem.sentence(5)
          }
        }
      })

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      user = standard_user_fixture()
      pat = get_pat(user.default_account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = patch(conn, "/v1/email_templates/#{UUID.generate()}", %{
        "data" => %{
          "type" => "EmailTemplate",
          "attributes" => %{
            "name" => Faker.Lorem.sentence(5)
          }
        }
      })

      assert conn.status == 403
    end

    test "with UAT requesting email_template of a different account", %{conn: conn} do
      user1 = standard_user_fixture()
      user2 = standard_user_fixture()
      email_template = email_template_fixture(user2.default_account)
      uat = get_uat(user1.default_account, user1)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/email_templates/#{email_template.id}", %{
        "data" => %{
          "type" => "EmailTemplate",
          "attributes" => %{
            "name" => Faker.Lorem.sentence(5)
          }
        }
      })

      assert conn.status == 404
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      email_template = email_template_fixture(user.default_account)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/email_templates/#{email_template.id}", %{
        "data" => %{
          "type" => "EmailTemplate",
          "attributes" => %{
            "name" => Faker.Lorem.sentence(5)
          }
        }
      })

      assert json_response(conn, 200)
    end
  end

  # Delete a email template
  describe "DELETE /v1/email_templates/:id" do
    test "without access token", %{conn: conn} do
      conn = delete(conn, "/v1/email_templates/#{UUID.generate()}")

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      user = standard_user_fixture()
      pat = get_pat(user.default_account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = delete(conn, "/v1/email_templates/#{UUID.generate()}")

      assert conn.status == 403
    end

    test "with UAT and requesting email_template of a different account", %{conn: conn} do
      user1 = standard_user_fixture()
      user2 = standard_user_fixture()
      email_template = email_template_fixture(user2.default_account)
      uat = get_uat(user1.default_account, user1)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = delete(conn, "/v1/email_templates/#{email_template.id}")

      assert conn.status == 404
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      email_template = email_template_fixture(user.default_account)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = delete(conn, "/v1/email_templates/#{email_template.id}")

      assert conn.status == 204
    end
  end

  # List email template
  describe "GET /v1/email_templates" do
    test "without access token", %{conn: conn} do
      conn = get(conn, "/v1/email_templates")

      assert conn.status == 401
    end

    test "with UAT", %{conn: conn} do
      user1 = standard_user_fixture()
      user2 = standard_user_fixture()

      email_template_fixture(user1.default_account)
      email_template_fixture(user1.default_account)
      email_template_fixture(user2.default_account)

      uat = get_uat(user1.default_account, user1)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/email_templates")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2
    end
  end
end
