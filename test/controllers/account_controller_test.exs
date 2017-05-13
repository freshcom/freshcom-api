defmodule BlueJet.AccountControllerTest do
  use BlueJet.ConnCase

  alias BlueJet.Account
  alias BlueJet.Repo

  @valid_attrs %{name: "some content"}
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
    conn = get conn, account_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    account = Repo.insert! %Account{}
    conn = get conn, account_path(conn, :show, account)
    data = json_response(conn, 200)["data"]
    assert data["id"] == "#{account.id}"
    assert data["type"] == "account"
    assert data["attributes"]["name"] == account.name
  end

  test "does not show resource and instead throw error when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, account_path(conn, :show, "11111111-1111-1111-1111-111111111111")
    end
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, account_path(conn, :create), %{
      "meta" => %{},
      "data" => %{
        "type" => "account",
        "attributes" => @valid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(Account, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, account_path(conn, :create), %{
      "meta" => %{},
      "data" => %{
        "type" => "account",
        "attributes" => @invalid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    account = Repo.insert! %Account{}
    conn = put conn, account_path(conn, :update, account), %{
      "meta" => %{},
      "data" => %{
        "type" => "account",
        "id" => account.id,
        "attributes" => @valid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(Account, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    account = Repo.insert! %Account{}
    conn = put conn, account_path(conn, :update, account), %{
      "meta" => %{},
      "data" => %{
        "type" => "account",
        "id" => account.id,
        "attributes" => @invalid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn} do
    account = Repo.insert! %Account{}
    conn = delete conn, account_path(conn, :delete, account)
    assert response(conn, 204)
    refute Repo.get(Account, account.id)
  end

end
