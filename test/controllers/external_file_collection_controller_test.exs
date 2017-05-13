defmodule BlueJet.ExternalFileCollectionControllerTest do
  use BlueJet.ConnCase

  alias BlueJet.ExternalFileCollection
  alias BlueJet.Repo

  @valid_attrs %{label: "some content", name: "some content", translations: %{}}
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
    conn = get conn, external_file_collection_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    external_file_collection = Repo.insert! %ExternalFileCollection{}
    conn = get conn, external_file_collection_path(conn, :show, external_file_collection)
    data = json_response(conn, 200)["data"]
    assert data["id"] == "#{external_file_collection.id}"
    assert data["type"] == "external_file_collection"
    assert data["attributes"]["name"] == external_file_collection.name
    assert data["attributes"]["label"] == external_file_collection.label
    assert data["attributes"]["translations"] == external_file_collection.translations
  end

  test "does not show resource and instead throw error when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, external_file_collection_path(conn, :show, "11111111-1111-1111-1111-111111111111")
    end
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, external_file_collection_path(conn, :create), %{
      "meta" => %{},
      "data" => %{
        "type" => "external_file_collection",
        "attributes" => @valid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(ExternalFileCollection, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, external_file_collection_path(conn, :create), %{
      "meta" => %{},
      "data" => %{
        "type" => "external_file_collection",
        "attributes" => @invalid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    external_file_collection = Repo.insert! %ExternalFileCollection{}
    conn = put conn, external_file_collection_path(conn, :update, external_file_collection), %{
      "meta" => %{},
      "data" => %{
        "type" => "external_file_collection",
        "id" => external_file_collection.id,
        "attributes" => @valid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(ExternalFileCollection, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    external_file_collection = Repo.insert! %ExternalFileCollection{}
    conn = put conn, external_file_collection_path(conn, :update, external_file_collection), %{
      "meta" => %{},
      "data" => %{
        "type" => "external_file_collection",
        "id" => external_file_collection.id,
        "attributes" => @invalid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn} do
    external_file_collection = Repo.insert! %ExternalFileCollection{}
    conn = delete conn, external_file_collection_path(conn, :delete, external_file_collection)
    assert response(conn, 204)
    refute Repo.get(ExternalFileCollection, external_file_collection.id)
  end

end
