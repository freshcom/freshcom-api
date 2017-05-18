defmodule BlueJet.ExternalFileControllerTest do
  use BlueJet.ConnCase

  alias BlueJet.ExternalFile
  alias BlueJet.Repo
  alias BlueJet.User
  alias BlueJet.UserRegistration
  alias BlueJet.Authentication

  @valid_attrs %{
    name: Faker.Lorem.word(),
    status: "pending",
    content_type: "image/png",
    size_bytes: 42
  }
  @invalid_attrs %{}

  setup do
    {_, %User{ default_account_id: account1_id, id: user1_id }} = UserRegistration.sign_up(%{
      first_name: Faker.Name.first_name(),
      last_name: Faker.Name.last_name(),
      email: "test1@example.com",
      password: "test1234",
      account_name: Faker.Company.name()
    })
    {:ok, %{ access_token: access_token }} = Authentication.get_token(%{ username: "test1@example.com", password: "test1234"}, nil)

    conn = build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    {:ok, conn: conn, access_token: access_token}
  end

  defp relationships do
    %{}
  end

  describe "GET /external_files" do
    test "with no Access Token" do
      conn = get(conn, external_file_path(conn, :index))
      assert conn.status == 401
    end

    test "with existing external files", %{ conn: conn, access_token: access_token } do
      conn = conn |> put_req_header("authorization", "Bearer #{access_token}")
      Repo.insert!(ExternalFile.changeset(%ExternalFile{}, @valid_attrs))

      conn = get(conn, external_file_path(conn, :index))
      assert length(json_response(conn, 200)["data"]) == 1
    end
  end

  describe "GET /external_files/:id" do
    test "with valid id", %{conn: conn} do
      external_file = Repo.insert!(ExternalFile.changeset(%ExternalFile{}, @valid_attrs))
      conn = get(conn, external_file_path(conn, :show, external_file))

      data = json_response(conn, 200)["data"]
      assert data["id"] == "#{external_file.id}"
      assert data["type"] == "ExternalFile"
      assert data["attributes"]["name"] == external_file.name
      assert data["attributes"]["status"] == external_file.status
      assert data["attributes"]["contentType"] == external_file.content_type
      assert data["attributes"]["sizeBytes"] == external_file.size_bytes
      assert data["attributes"]["publicReadable"] == external_file.public_readable
    end

    test "with invalid id", %{conn: conn} do
      assert_error_sent(404, fn ->
        get conn, external_file_path(conn, :show, "11111111-1111-1111-1111-111111111111")
      end)
    end
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, external_file_path(conn, :create), %{
      "meta" => %{},
      "data" => %{
        "type" => "external_file",
        "attributes" => @valid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(ExternalFile, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, external_file_path(conn, :create), %{
      "meta" => %{},
      "data" => %{
        "type" => "external_file",
        "attributes" => @invalid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    external_file = Repo.insert! %ExternalFile{}
    conn = put conn, external_file_path(conn, :update, external_file), %{
      "meta" => %{},
      "data" => %{
        "type" => "external_file",
        "id" => external_file.id,
        "attributes" => @valid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(ExternalFile, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    external_file = Repo.insert! %ExternalFile{}
    conn = put conn, external_file_path(conn, :update, external_file), %{
      "meta" => %{},
      "data" => %{
        "type" => "external_file",
        "id" => external_file.id,
        "attributes" => @invalid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn} do
    external_file = Repo.insert! %ExternalFile{}
    conn = delete conn, external_file_path(conn, :delete, external_file)
    assert response(conn, 204)
    refute Repo.get(ExternalFile, external_file.id)
  end

end
