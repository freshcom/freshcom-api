defmodule BlueJet.S3FileSetControllerTest do
  use BlueJet.ConnCase

  alias BlueJet.S3FileSet
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
    conn = get conn, s3_file_set_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    s3_file_set = Repo.insert! %S3FileSet{}
    conn = get conn, s3_file_set_path(conn, :show, s3_file_set)
    data = json_response(conn, 200)["data"]
    assert data["id"] == "#{s3_file_set.id}"
    assert data["type"] == "s3_file_set"
    assert data["attributes"]["name"] == s3_file_set.name
    assert data["attributes"]["label"] == s3_file_set.label
    assert data["attributes"]["translations"] == s3_file_set.translations
  end

  test "does not show resource and instead throw error when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, s3_file_set_path(conn, :show, "11111111-1111-1111-1111-111111111111")
    end
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, s3_file_set_path(conn, :create), %{
      "meta" => %{},
      "data" => %{
        "type" => "s3_file_set",
        "attributes" => @valid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(S3FileSet, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, s3_file_set_path(conn, :create), %{
      "meta" => %{},
      "data" => %{
        "type" => "s3_file_set",
        "attributes" => @invalid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    s3_file_set = Repo.insert! %S3FileSet{}
    conn = put conn, s3_file_set_path(conn, :update, s3_file_set), %{
      "meta" => %{},
      "data" => %{
        "type" => "s3_file_set",
        "id" => s3_file_set.id,
        "attributes" => @valid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(S3FileSet, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    s3_file_set = Repo.insert! %S3FileSet{}
    conn = put conn, s3_file_set_path(conn, :update, s3_file_set), %{
      "meta" => %{},
      "data" => %{
        "type" => "s3_file_set",
        "id" => s3_file_set.id,
        "attributes" => @invalid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn} do
    s3_file_set = Repo.insert! %S3FileSet{}
    conn = delete conn, s3_file_set_path(conn, :delete, s3_file_set)
    assert response(conn, 204)
    refute Repo.get(S3FileSet, s3_file_set.id)
  end

end
