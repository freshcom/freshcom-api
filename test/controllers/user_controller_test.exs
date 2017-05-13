defmodule BlueJet.UserControllerTest do
  use BlueJet.ConnCase

  alias BlueJet.User
  alias BlueJet.Repo

  @valid_attrs %{email: "some content", encrypted_password: "some content", first_name: "some content", last_name: "some content"}
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
    conn = get conn, user_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    user = Repo.insert! %User{}
    conn = get conn, user_path(conn, :show, user)
    data = json_response(conn, 200)["data"]
    assert data["id"] == "#{user.id}"
    assert data["type"] == "user"
    assert data["attributes"]["email"] == user.email
    assert data["attributes"]["encrypted_password"] == user.encrypted_password
    assert data["attributes"]["first_name"] == user.first_name
    assert data["attributes"]["last_name"] == user.last_name
  end

  test "does not show resource and instead throw error when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, user_path(conn, :show, "11111111-1111-1111-1111-111111111111")
    end
  end

  test "/v1/users", %{conn: conn} do
    attributes = %{
      email: Faker.Internet.email,
      password: "test1234",
      first_name: Faker.Name.first_name,
      last_name: Faker.Name.last_name
    }
    conn = post conn, "/v1/users", %{
      "data" => %{
        "type" => "User",
        "attributes" => attributes
      }
    }

    data = json_response(conn, 201)["data"]

    assert data["id"]
    assert data["attributes"]["email"] == attributes.email
    assert data["attributes"]["firstName"] == attributes.first_name
    assert data["attributes"]["lastName"] == attributes.last_name
    refute data["attributes"]["password"]
    refute data["attributes"]["encryptedPassword"]
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, user_path(conn, :create), %{
      "meta" => %{},
      "data" => %{
        "type" => "user",
        "attributes" => @invalid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    user = Repo.insert! %User{}
    conn = put conn, user_path(conn, :update, user), %{
      "meta" => %{},
      "data" => %{
        "type" => "user",
        "id" => user.id,
        "attributes" => @valid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(User, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    user = Repo.insert! %User{}
    conn = put conn, user_path(conn, :update, user), %{
      "meta" => %{},
      "data" => %{
        "type" => "user",
        "id" => user.id,
        "attributes" => @invalid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn} do
    user = Repo.insert! %User{}
    conn = delete conn, user_path(conn, :delete, user)
    assert response(conn, 204)
    refute Repo.get(User, user.id)
  end

end
