defmodule BlueJet.CustomerControllerTest do
  use BlueJet.ConnCase

  alias BlueJet.Customer
  alias BlueJet.Repo

  @valid_attrs %{display_name: "some content", email: "some content", encrypted_password: "some content", first_name: "some content", last_name: "some content"}
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
    conn = get conn, customer_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    customer = Repo.insert! %Customer{}
    conn = get conn, customer_path(conn, :show, customer)
    data = json_response(conn, 200)["data"]
    assert data["id"] == "#{customer.id}"
    assert data["type"] == "customer"
    assert data["attributes"]["first_name"] == customer.first_name
    assert data["attributes"]["last_name"] == customer.last_name
    assert data["attributes"]["email"] == customer.email
    assert data["attributes"]["encrypted_password"] == customer.encrypted_password
    assert data["attributes"]["display_name"] == customer.display_name
  end

  test "does not show resource and instead throw error when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, customer_path(conn, :show, "11111111-1111-1111-1111-111111111111")
    end
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, customer_path(conn, :create), %{
      "meta" => %{},
      "data" => %{
        "type" => "customer",
        "attributes" => @valid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(Customer, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, customer_path(conn, :create), %{
      "meta" => %{},
      "data" => %{
        "type" => "customer",
        "attributes" => @invalid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    customer = Repo.insert! %Customer{}
    conn = put conn, customer_path(conn, :update, customer), %{
      "meta" => %{},
      "data" => %{
        "type" => "customer",
        "id" => customer.id,
        "attributes" => @valid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(Customer, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    customer = Repo.insert! %Customer{}
    conn = put conn, customer_path(conn, :update, customer), %{
      "meta" => %{},
      "data" => %{
        "type" => "customer",
        "id" => customer.id,
        "attributes" => @invalid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn} do
    customer = Repo.insert! %Customer{}
    conn = delete conn, customer_path(conn, :delete, customer)
    assert response(conn, 204)
    refute Repo.get(Customer, customer.id)
  end

end
