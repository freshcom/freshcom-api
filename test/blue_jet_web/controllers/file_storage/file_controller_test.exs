defmodule BlueJetWeb.FileControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper
  import BlueJet.FileStorage.TestHelper

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{ conn: conn }
  end

  # List file
  describe "GET /v1/files" do
    test "without access token", %{conn: conn} do
      conn = get(conn, "/v1/files")

      assert conn.status == 401
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      file_fixture(user.default_account, %{status: "uploaded"})
      file_fixture(user.default_account, %{status: "uploaded"})
      file_fixture(user.default_account, %{status: "uploaded"})
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/files")

      response = json_response(conn, 200)

      assert length(response["data"]) == 3
    end
  end

  # Create a file
  describe "POST /v1/files" do
    test "without access token", %{conn: conn} do
      conn = post(conn, "/v1/files", %{
        "data" => %{
          "type" => "File"
        }
      })

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      user = standard_user_fixture()
      pat = get_pat(user.default_account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = post(conn, "/v1/files", %{
        "data" => %{
          "type" => "File",
          "attributes" => %{
            "name" => Faker.File.file_name(),
            "content_type" => Faker.File.mime_type(),
            "size_bytes" => System.unique_integer([:positive])
          }
        }
      })

      assert json_response(conn, 201)
    end
  end

  # Retrieve a file
  describe "GET /v1/files/:id" do
    test "without access token", %{conn: conn} do
      conn = get(conn, "/v1/files/#{UUID.generate()}")

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      account = account_fixture()
      file = file_fixture(account, %{status: "uploaded"})
      pat = get_pat(account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = get(conn, "/v1/files/#{file.id}")

      assert json_response(conn, 200)
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      file = file_fixture(user.default_account, %{status: "uploaded"})
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/files/#{file.id}")

      assert json_response(conn, 200)
    end
  end

  # Update a file
  describe "PATCH /v1/files/:id" do
    test "without access token", %{conn: conn} do
      conn = patch(conn, "/v1/files/#{UUID.generate()}", %{
        "data" => %{
          "type" => "File",
          "attributes" => %{
            "status" => "uploaded"
          }
        }
      })

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      account = account_fixture()
      file = file_fixture(account)
      pat = get_pat(account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = patch(conn, "/v1/files/#{file.id}", %{
        "data" => %{
          "type" => "File",
          "attributes" => %{
            "status" => "uploaded"
          }
        }
      })

      assert conn.status == 200
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      file = file_fixture(user.default_account)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/files/#{file.id}", %{
        "data" => %{
          "type" => "File",
          "attributes" => %{
            "status" => "uploaded"
          }
        }
      })

      assert json_response(conn, 200)
    end
  end

  # Delete a file
  describe "DELETE /v1/files/:id" do
    test "without access token", %{conn: conn} do
      conn = delete(conn, "/v1/files/#{UUID.generate()}")

      assert conn.status == 401
    end

    test "with UAT", %{conn: conn} do
      user = standard_user_fixture()
      file = file_fixture(user.default_account)
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = delete(conn, "/v1/files/#{file.id}")

      assert conn.status == 204
    end
  end
end
