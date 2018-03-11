defmodule BlueJet.CrmTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity.Account
  alias BlueJet.Crm
  alias BlueJet.Crm.{Customer, PointTransaction}
  alias BlueJet.Crm.ServiceMock

  describe "list_customer/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Crm.list_customer(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      request = %AccessRequest{
        role: "developer",
        account: account
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:list_customer, fn(_, opts) ->
          assert opts[:account] == account

          [%Customer{}]
         end)
      |> expect(:count_customer, fn(_, opts) ->
          assert opts[:account] == account

          1
         end)
      |> expect(:count_customer, fn(_, opts) ->
          assert opts[:account] == account

          1
         end)

      {:ok, response} = Crm.list_customer(request)

      assert length(response.data) == 1
      assert response.meta.all_count == 1
      assert response.meta.total_count == 1
    end
  end

  describe "create_customer/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Crm.create_customer(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      customer = %Customer{}
      request = %AccessRequest{
        account: account,
        fields: %{
          "status" => "registered",
          "name" => Faker.Name.name(),
          "email" => Faker.Internet.safe_email()
        }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:create_customer, fn(fields, opts) ->
          assert fields == Map.merge(request.fields, %{ "role" => "customer" })
          assert opts[:account] == account

          {:ok, customer}
         end)

      {:ok, response} = Crm.create_customer(request)

      assert response.data == customer
    end
  end

  describe "get_customer/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Crm.get_customer(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      customer = %Customer{}
      request = %AccessRequest{
        account: account,
        params: %{ "id" => customer.id }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:get_customer, fn(identifiers, opts) ->
          assert identifiers[:id] == request.params["id"]
          assert opts[:account] == account

          customer
         end)

      {:ok, response} = Crm.get_customer(request)

      assert response.data == customer
    end
  end

  describe "update_customer/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Crm.update_customer(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      customer = %Customer{}
      request = %AccessRequest{
        account: account,
        params: %{ "id" => customer.id },
        fields: %{ "status" => "registered" }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:update_customer, fn(id, fields, opts) ->
          assert id == request.params["id"]
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, customer}
         end)

      {:ok, response} = Crm.update_customer(request)

      assert response.data == customer
    end
  end

  describe "delete_customer/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Crm.delete_customer(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      customer = %Customer{}
      request = %AccessRequest{
        account: account,
        params: %{ "id" => customer.id }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:delete_customer, fn(id, opts) ->
          assert id == request.params["id"]
          assert opts[:account] == account

          {:ok, customer}
         end)

      {:ok, _} = Crm.delete_customer(request)
    end
  end

  describe "list_point_transaction/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Crm.list_point_transaction(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        params: %{ "point_account_id" => Ecto.UUID.generate() }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:list_point_transaction, fn(params, opts) ->
          assert params[:filter][:status] == "committed"
          assert params[:filter][:point_account_id] == request.params["point_account_id"]
          assert opts[:account] == account

          [%PointTransaction{}]
         end)
      |> expect(:count_point_transaction, fn(params, opts) ->
          assert params[:filter][:status] == "committed"
          assert params[:filter][:point_account_id] == request.params["point_account_id"]
          assert opts[:account] == account

          1
         end)
      |> expect(:count_point_transaction, fn(params, opts) ->
          assert params[:filter][:status] == "committed"
          assert params[:filter][:point_account_id] == request.params["point_account_id"]
          assert opts[:account] == account

          1
         end)

      {:ok, response} = Crm.list_point_transaction(request)

      assert length(response.data) == 1
    end
  end

  describe "create_point_transaction/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Crm.create_point_transaction(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      point_transaction = %PointTransaction{}
      request = %AccessRequest{
        account: account,
        params: %{ "point_account_id" => Ecto.UUID.generate() },
        fields: %{ "amount" => 5000 }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:create_point_transaction, fn(fields, opts) ->
          assert fields == Map.merge(request.fields, %{ "point_account_id" => request.params["point_account_id"] })
          assert opts[:account] == account

          {:ok, point_transaction}
         end)

      {:ok, response} = Crm.create_point_transaction(request)

      assert response.data == point_transaction
    end
  end

  describe "get_point_transaction/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Crm.get_point_transaction(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      point_transaction = %PointTransaction{}
      request = %AccessRequest{
        account: account,
        params: %{ "id" => point_transaction.id }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      ServiceMock
      |> expect(:get_point_transaction, fn(identifiers, opts) ->
          assert identifiers[:id] == request.params["id"]
          assert opts[:account] == account

          point_transaction
         end)

      {:ok, response} = Crm.get_point_transaction(request)

      assert response.data == point_transaction
    end
  end

  describe "update_point_transaction/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Crm.update_point_transaction(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      point_transaction = %PointTransaction{}
      request = %AccessRequest{
        account: account,
        params: %{ "id" => point_transaction.id },
        fields: %{ "name" => Faker.String.base64(5) }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      ServiceMock
      |> expect(:update_point_transaction, fn(id, fields, opts) ->
          assert id == request.params["id"]
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, point_transaction}
         end)

      {:ok, response} = Crm.update_point_transaction(request)

      assert response.data == point_transaction
    end
  end

  describe "delete_point_transaction/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Crm.delete_point_transaction(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      point_transaction = %PointTransaction{}
      request = %AccessRequest{
        account: account,
        params: %{ "id" => point_transaction.id }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      ServiceMock
      |> expect(:delete_point_transaction, fn(id, opts) ->
          assert id == request.params["id"]
          assert opts[:account] == account

          {:ok, point_transaction}
         end)

      {:ok, _} = Crm.delete_point_transaction(request)
    end
  end
end
