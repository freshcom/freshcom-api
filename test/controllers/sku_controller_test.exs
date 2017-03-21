defmodule BlueJet.SkuControllerTest do
  use BlueJet.ConnCase

  alias BlueJet.Sku
  alias BlueJet.Repo

  @valid_attrs %{name: "some content", number: "some content", print_name: "some content"}
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
    conn = get conn, sku_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    sku = Repo.insert! %Sku{ name: "test", print_name: "TEST" }
    conn = get conn, sku_path(conn, :show, sku)
    data = json_response(conn, 200)["data"]
    assert data["id"] == "#{sku.id}"
    assert data["type"] == "sku"
    assert data["attributes"]["number"] == sku.number
    assert data["attributes"]["name"] == sku.name
    assert data["attributes"]["printName"] == sku.print_name
  end

  test "does not show resource and instead throw error when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, sku_path(conn, :show, "11111111-1111-1111-1111-111111111111")
    end
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, sku_path(conn, :create), %{
      "meta" => %{},
      "data" => %{
        "type" => "sku",
        "attributes" => @valid_attrs,
        "relationships" => relationships()
      }
    }

    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(Sku, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, sku_path(conn, :create), %{
      "meta" => %{},
      "data" => %{
        "type" => "sku",
        "attributes" => @invalid_attrs,
        "relationships" => relationships()
      }
    }

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    sku = Repo.insert! %Sku{ name: "test", print_name: "TEST" }
    conn = put conn, sku_path(conn, :update, sku), %{
      "meta" => %{},
      "data" => %{
        "type" => "sku",
        "id" => sku.id,
        "attributes" => @valid_attrs,
        "relationships" => relationships()
      }
    }

    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(Sku, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    sku = Repo.insert! %Sku{ name: "test", print_name: "TEST" }
    conn = put conn, sku_path(conn, :update, sku), %{
      "meta" => %{},
      "data" => %{
        "type" => "sku",
        "id" => sku.id,
        "attributes" => @invalid_attrs,
        "relationships" => relationships()
      }
    }

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn} do
    sku = Repo.insert! %Sku{ name: "test", print_name: "TEST" }
    conn = delete conn, sku_path(conn, :delete, sku)
    assert response(conn, 204)
    refute Repo.get(Sku, sku.id)
  end

end
