defmodule BlueJetWeb.DataImportControllerTest do
  use BlueJetWeb.ConnCase

  import BlueJet.Identity.TestHelper

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{conn: conn}
  end

  # Create a data import
  describe "POST /v1/data_imports" do
    test "without access token", %{conn: conn} do
      conn = post(conn, "/v1/data_imports", %{
        "data" => %{
          "type" => "DataImport"
        }
      })

      assert conn.status == 401
    end

    test "with PAT", %{conn: conn} do
      user = standard_user_fixture()
      pat = get_pat(user.default_account)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = post(conn, "/v1/data_imports", %{
        "data" => %{
          "type" => "DataImport"
        }
      })

      assert conn.status == 403
    end

    test "with no attributes", %{conn: conn} do
      user = standard_user_fixture()
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/data_imports", %{
        "data" => %{
          "type" => "DataImport"
        }
      })

      response = json_response(conn, 422)
      assert length(response["errors"]) == 2
    end

    test "with valid attributes", %{conn: conn} do
      user = standard_user_fixture()
      uat = get_uat(user.default_account, user)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/data_imports", %{
        "data" => %{
          "type" => "DataImport",
          "attributes" => %{
            "data_url" => Faker.Internet.url(),
            "data_type" => "Stockable"
          }
        }
      })

      assert json_response(conn, 201)
    end
  end
end
