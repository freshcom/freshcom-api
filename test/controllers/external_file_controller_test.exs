defmodule BlueJet.ExternalFileControllerTest do
  use BlueJet.ConnCase

  alias BlueJet.ExternalFile
  alias BlueJet.Repo

  @valid_attrs %{content_type: "some content", name: "some content", original_id: "7488a646-e31f-11e4-aace-600308960662", public_readable: true, size_bytes: 42, status: "some content", system_tag: "some content", version_name: "some content"}
  @invalid_attrs %{}

  setup do
    conn = build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    {:ok, conn: conn}
  end

  defp relationships do
    %{}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, external_file_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    external_file = Repo.insert! %ExternalFile{}
    conn = get conn, external_file_path(conn, :show, external_file)
    data = json_response(conn, 200)["data"]
    assert data["id"] == "#{external_file.id}"
    assert data["type"] == "external_file"
    assert data["attributes"]["name"] == external_file.name
    assert data["attributes"]["status"] == external_file.status
    assert data["attributes"]["content_type"] == external_file.content_type
    assert data["attributes"]["size_bytes"] == external_file.size_bytes
    assert data["attributes"]["public_readable"] == external_file.public_readable
    assert data["attributes"]["version_name"] == external_file.version_name
    assert data["attributes"]["system_tag"] == external_file.system_tag
    assert data["attributes"]["original_id"] == external_file.original_id
  end

  test "does not show resource and instead throw error when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, external_file_path(conn, :show, "11111111-1111-1111-1111-111111111111")
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
