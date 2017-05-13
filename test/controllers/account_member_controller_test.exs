defmodule BlueJet.AccountMemberControllerTest do
  use BlueJet.ConnCase

  alias BlueJet.AccountMember
  alias BlueJet.Repo

  @valid_attrs %{role: "some content"}
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
    conn = get conn, account_member_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    account_member = Repo.insert! %AccountMember{}
    conn = get conn, account_member_path(conn, :show, account_member)
    data = json_response(conn, 200)["data"]
    assert data["id"] == "#{account_member.id}"
    assert data["type"] == "account_member"
    assert data["attributes"]["role"] == account_member.role
  end

  test "does not show resource and instead throw error when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, account_member_path(conn, :show, "11111111-1111-1111-1111-111111111111")
    end
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, account_member_path(conn, :create), %{
      "meta" => %{},
      "data" => %{
        "type" => "account_member",
        "attributes" => @valid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(AccountMember, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, account_member_path(conn, :create), %{
      "meta" => %{},
      "data" => %{
        "type" => "account_member",
        "attributes" => @invalid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    account_member = Repo.insert! %AccountMember{}
    conn = put conn, account_member_path(conn, :update, account_member), %{
      "meta" => %{},
      "data" => %{
        "type" => "account_member",
        "id" => account_member.id,
        "attributes" => @valid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(AccountMember, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    account_member = Repo.insert! %AccountMember{}
    conn = put conn, account_member_path(conn, :update, account_member), %{
      "meta" => %{},
      "data" => %{
        "type" => "account_member",
        "id" => account_member.id,
        "attributes" => @invalid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn} do
    account_member = Repo.insert! %AccountMember{}
    conn = delete conn, account_member_path(conn, :delete, account_member)
    assert response(conn, 204)
    refute Repo.get(AccountMember, account_member.id)
  end

end
