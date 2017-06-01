defmodule BlueJet.ExternalFileCollectionControllerTest do
  use BlueJet.ConnCase

  alias BlueJet.User
  alias BlueJet.UserRegistration
  alias BlueJet.Authentication

  alias BlueJet.ExternalFileCollection
  alias BlueJet.Repo

  @valid_attrs %{
    "label" => "primary_images"
  }
  @invalid_attrs %{
    "label" => ""
  }

  setup do
    {_, %User{ default_account_id: account1_id }} = UserRegistration.sign_up(%{
      first_name: Faker.Name.first_name(),
      last_name: Faker.Name.last_name(),
      email: "test1@example.com",
      password: "test1234",
      account_name: Faker.Company.name()
    })
    {:ok, %{ access_token: uat1 }} = Authentication.get_token(%{ username: "test1@example.com", password: "test1234", scope: "type:user" })

    conn = build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{ conn: conn, uat1: uat1, account1_id: account1_id }
  end

  describe "POST /v1/external_file_collections" do
    test "with no access token", %{ conn: conn } do
      conn = post(conn, external_file_collection_path(conn, :create), %{
        "data" => %{
          "type" => "ExternalFileCollection",
          "attributes" => @valid_attrs
        }
      })

      assert conn.status == 401
    end

    test "with invalid attrs", %{ conn: conn, uat1: uat1 } do
      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = post(conn, external_file_collection_path(conn, :create), %{
        "data" => %{
          "type" => "ExternalFileCollection",
          "attributes" => @invalid_attrs
        }
      })

      assert json_response(conn, 422)["errors"]
      assert length(json_response(conn, 422)["errors"]) > 0
    end

    test "with valid attrs", %{ conn: conn, uat1: uat1 } do
      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = post(conn, external_file_collection_path(conn, :create), %{
        "data" => %{
          "type" => "ExternalFileCollection",
          "attributes" => @valid_attrs
        }
      })

      assert json_response(conn, 201)["data"]["id"]
      assert json_response(conn, 201)["data"]["attributes"]["label"] == @valid_attrs["label"]
    end
  end

  describe "GET /v1/external_file_collections/:id" do
    test "with no access token", %{ conn: conn } do
      conn = get(conn, external_file_collection_path(conn, :show, "test"))

      assert conn.status == 401
    end

    test "with with access token of a different account", %{ conn: conn, uat1: uat1 } do
      {_, %User{ default_account_id: account2_id }} = UserRegistration.sign_up(%{
        first_name: Faker.Name.first_name(),
        last_name: Faker.Name.last_name(),
        email: "test2@example.com",
        password: "test1234",
        account_name: Faker.Company.name()
      })

      efc = Repo.insert!(%ExternalFileCollection{
        account_id: account2_id,
        label: "primary_images"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      assert_error_sent(404, fn ->
        get(conn, external_file_collection_path(conn, :show, efc.id))
      end)
    end

    test "with valid access token and id", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      efc = Repo.insert!(%ExternalFileCollection{
        account_id: account1_id,
        label: "primary_images"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, external_file_collection_path(conn, :show, efc.id))

      assert json_response(conn, 200)["data"]["id"] == efc.id
      assert json_response(conn, 200)["data"]["attributes"]
    end
  end

  describe "PATCH /v1/external_file_collections/:id" do
    test "with no access token", %{ conn: conn } do
      conn = patch(conn, external_file_collection_path(conn, :update, "test"), %{
        "data" => %{
          "id" => "test",
          "type" => "ExternalFileCollection",
          "attributes" => @valid_attrs
        }
      })

      assert conn.status == 401
    end

    test "with access token of a different account", %{ conn: conn, uat1: uat1 } do
      {_, %User{ default_account_id: account2_id }} = UserRegistration.sign_up(%{
        first_name: Faker.Name.first_name(),
        last_name: Faker.Name.last_name(),
        email: "test2@example.com",
        password: "test1234",
        account_name: Faker.Company.name()
      })

      efc = Repo.insert!(%ExternalFileCollection{
        account_id: account2_id,
        label: "secondary_images"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      assert_error_sent(404, fn ->
        patch(conn, external_file_collection_path(conn, :update, efc.id), %{
          "data" => %{
            "id" => efc.id,
            "type" => "ExternalFileCollection",
            "attributes" => @valid_attrs
          }
        })
      end)
    end

    test "with good access token but invalid attrs", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      efc = Repo.insert!(%ExternalFileCollection{
        account_id: account1_id,
        label: "primary_images"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = patch(conn, external_file_collection_path(conn, :update, efc.id), %{
        "data" => %{
          "id" => efc.id,
          "type" => "ExternalFileCollection",
          "attributes" => @invalid_attrs
        }
      })

      assert json_response(conn, 422)["errors"]
      assert length(json_response(conn, 422)["errors"]) > 0
    end

    test "with good access token and valid attrs", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      efc = Repo.insert!(%ExternalFileCollection{
        account_id: account1_id,
        label: "secondary_images"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = patch(conn, external_file_collection_path(conn, :update, efc.id), %{
        "data" => %{
          "id" => efc.id,
          "type" => "ExternalFileCollection",
          "attributes" => @valid_attrs
        }
      })

      assert json_response(conn, 200)["data"]["id"]
      assert json_response(conn, 200)["data"]["attributes"]["label"] == @valid_attrs["label"]
    end
  end

  describe "GET /v1/external_file_collections" do
    test "with no access token", %{ conn: conn } do
      conn = get(conn, external_file_collection_path(conn, :index))

      assert conn.status == 401
    end

    test "with good access token", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      {_, %User{ default_account_id: account2_id }} = UserRegistration.sign_up(%{
        first_name: Faker.Name.first_name(),
        last_name: Faker.Name.last_name(),
        email: "test2@example.com",
        password: "test1234",
        account_name: Faker.Company.name()
      })

      Repo.insert!(%ExternalFileCollection{
        account_id: account2_id,
        label: "primary_images"
      })
      Repo.insert!(%ExternalFileCollection{
        account_id: account1_id,
        label: "primary_images"
      })
      Repo.insert!(%ExternalFileCollection{
        account_id: account1_id,
        label: "secondary_images"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = get(conn, external_file_collection_path(conn, :index))

      assert length(json_response(conn, 200)["data"]) == 2
    end
  end

  describe "DELETE /v1/external_file_collections/:id" do
    test "with no access token", %{ conn: conn } do
      conn = delete(conn, external_file_collection_path(conn, :delete, "test"))

      assert conn.status == 401
    end

    test "with with access token of a different account", %{ conn: conn, uat1: uat1 } do
      {_, %User{ default_account_id: account2_id }} = UserRegistration.sign_up(%{
        first_name: Faker.Name.first_name(),
        last_name: Faker.Name.last_name(),
        email: "test2@example.com",
        password: "test1234",
        account_name: Faker.Company.name()
      })

      efc = Repo.insert!(%ExternalFileCollection{
        account_id: account2_id,
        label: "secondary_images"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      assert_error_sent(404, fn ->
        delete(conn, external_file_collection_path(conn, :delete, efc.id))
      end)
    end

    test "with valid access token and id", %{ conn: conn, uat1: uat1, account1_id: account1_id } do
      efc = Repo.insert!(%ExternalFileCollection{
        account_id: account1_id,
        label: "secondary_images"
      })

      conn = put_req_header(conn, "authorization", "Bearer #{uat1}")

      conn = delete(conn, external_file_collection_path(conn, :delete, efc.id))

      assert conn.status == 204
    end
  end
end
