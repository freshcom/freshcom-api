defmodule BlueJet.JwtControllerTest do
  use BlueJet.ConnCase

  alias BlueJet.Jwt
  alias BlueJet.Repo

  @valid_attrs %{name: "some content", system_tag: "some content", value: "some content"}
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
    conn = get conn, jwt_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    jwt = Repo.insert! %Jwt{}
    conn = get conn, jwt_path(conn, :show, jwt)
    data = json_response(conn, 200)["data"]
    assert data["id"] == "#{jwt.id}"
    assert data["type"] == "jwt"
    assert data["attributes"]["value"] == jwt.value
    assert data["attributes"]["name"] == jwt.name
    assert data["attributes"]["system_tag"] == jwt.system_tag
  end

  test "does not show resource and instead throw error when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, jwt_path(conn, :show, "11111111-1111-1111-1111-111111111111")
    end
  end

  @tag :focus
  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, jwt_path(conn, :create), %{
      "meta" => %{},
      "data" => %{
        "type" => "jwt",
        "attributes" => @valid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(Jwt, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, jwt_path(conn, :create), %{
      "meta" => %{},
      "data" => %{
        "type" => "jwt",
        "attributes" => @invalid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    jwt = Repo.insert! %Jwt{}
    conn = put conn, jwt_path(conn, :update, jwt), %{
      "meta" => %{},
      "data" => %{
        "type" => "jwt",
        "id" => jwt.id,
        "attributes" => @valid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(Jwt, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    jwt = Repo.insert! %Jwt{}
    conn = put conn, jwt_path(conn, :update, jwt), %{
      "meta" => %{},
      "data" => %{
        "type" => "jwt",
        "id" => jwt.id,
        "attributes" => @invalid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn} do
    jwt = Repo.insert! %Jwt{}
    conn = delete conn, jwt_path(conn, :delete, jwt)
    assert response(conn, 204)
    refute Repo.get(Jwt, jwt.id)
  end

end
