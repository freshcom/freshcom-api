defmodule BlueJet.CrmTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity.{Account, User}
  alias BlueJet.Crm
  alias BlueJet.Crm.{Customer, PointTransaction}
  alias BlueJet.Crm.ServiceMock

  describe "list_customer/1" do
    test "when role is not authorized" do
      request = %AccessRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, error} = Crm.list_customer(request)
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        user: %User{},
        role: "administrator"
      }

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

      {:ok, _} = Crm.list_customer(request)
    end
  end

  describe "create_customer/1" do
    test "when role is not authorized" do
      request = %AccessRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, error} = Crm.create_customer(request)
      assert error == :access_denied
    end

    test "when role is guest" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        user: nil,
        role: "guest",
        fields: %{
          "status" => "guest",
          "name" => Faker.Name.name(),
          "email" => Faker.Internet.safe_email()
        }
      }

      ServiceMock
      |> expect(:create_customer, fn(fields, opts) ->
          assert fields["status"] == "registered"
          assert opts[:account] == account

          {:ok, %Customer{}}
         end)

      {:ok, _} = Crm.create_customer(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        user: %User{},
        role: "administrator",
        fields: %{
          "status" => "guest",
          "name" => Faker.Name.name(),
          "email" => Faker.Internet.safe_email()
        }
      }

      ServiceMock
      |> expect(:create_customer, fn(fields, opts) ->
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, %Customer{}}
         end)

      {:ok, _} = Crm.create_customer(request)
    end
  end

  describe "get_customer/1" do
    test "when role is not authorized" do
      request = %AccessRequest{
        account: nil,
        user: nil,
        role: "anonymous"
      }

      {:error, error} = Crm.get_customer(request)
      assert error == :access_denied
    end

    test "when role is guest" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        user: nil,
        role: "guest",
        params: %{ "id" => Ecto.UUID.generate(), "code" => "test", "name" => Faker.Name.name() }
      }

      ServiceMock
      |> expect(:get_customer, fn(identifiers, opts) ->
          refute identifiers[:id]
          assert identifiers[:code] == request.params["code"]
          assert identifiers[:name] == request.params["name"]
          assert opts[:account] == account

          %Customer{}
         end)

      {:ok, _} = Crm.get_customer(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        user: %User{},
        role: "administrator",
        params: %{ "id" => Ecto.UUID.generate() }
      }

      ServiceMock
      |> expect(:get_customer, fn(identifiers, opts) ->
          assert identifiers[:id] == request.params["id"]
          assert opts[:account] == account

          %Customer{}
         end)

      {:ok, _} = Crm.get_customer(request)
    end
  end

  describe "update_customer/1" do
    test "when role is not authorized" do
      request = %AccessRequest{
        account: %Account{},
        user: nil,
        role: "guest"
      }

      {:error, error} = Crm.update_customer(request)
      assert error == :access_denied
    end

    test "when role is customer" do
      account = %Account{}
      user = %User{ id: Ecto.UUID.generate() }
      customer = %Customer{ id: Ecto.UUID.generate() }
      request = %AccessRequest{
        account: account,
        user: user,
        role: "customer",
        fields: %{ "name" => Faker.Name.name() }
      }

      ServiceMock
      |> expect(:get_customer, fn(identifiers, opts) ->
          assert identifiers[:user_id] == user.id
          assert opts[:account] == account

          customer
         end)

      ServiceMock
      |> expect(:update_customer, fn(id, fields, opts) ->
          assert id == customer.id
          assert fields == request.fields
          assert opts[:account] == account
          refute opts[:bypass_user_pvc_validation]

          {:ok, %Customer{}}
         end)

      {:ok, _} = Crm.update_customer(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        user: %User{},
        role: "administrator",
        params: %{ "id" => Ecto.UUID.generate() },
        fields: %{ "name" => Faker.Name.name() }
      }

      ServiceMock
      |> expect(:update_customer, fn(id, fields, opts) ->
          assert id == request.params["id"]
          assert fields == request.fields
          assert opts[:account] == account
          assert opts[:bypass_user_pvc_validation]

          {:ok, %Customer{}}
         end)

      {:ok, _} = Crm.update_customer(request)
    end
  end

  describe "delete_customer/1" do
    test "when role is not authorized" do
      request = %AccessRequest{
        account: %Account{},
        user: nil,
        role: "guest"
      }

      {:error, error} = Crm.delete_customer(request)
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        user: %User{},
        role: "administrator",
        params: %{ "id" => Ecto.UUID.generate() }
      }

      ServiceMock
      |> expect(:delete_customer, fn(id, opts) ->
          assert id == request.params["id"]
          assert opts[:account] == account

          {:ok, %Customer{}}
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
