defmodule BlueJet.BalanceTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity.{Account, User}
  alias BlueJet.Balance
  alias BlueJet.Balance.{Settings, Card, Payment, Refund}
  alias BlueJet.Balance.{CRMServiceMock}
  alias BlueJet.Balance.ServiceMock

  #
  # MARK: Settings
  #
  describe "get_settings/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, error} = Balance.get_settings(request)
      assert error == :access_denied
    end

    test "when request is valid" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "administrator"
      }

      ServiceMock
      |> expect(:get_settings, fn(_) ->
          {:ok, %Settings{}}
         end)

      {:ok, _} = Balance.get_settings(request)
    end
  end

  describe "update_settings/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, error} = Balance.update_settings(request)
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator"
      }

      ServiceMock
      |> expect(:update_settings, fn(_, opts) ->
          assert opts[:account] == account

          {:ok, %Settings{}}
         end)

      {:ok, _} = Balance.update_settings(request)
    end
  end

  #
  # MARK: Cards
  #
  describe "list_card/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: nil,
        role: "guest"
      }

      {:error, error} = Balance.list_card(request)
      assert error == :access_denied
    end

    test "when role is customer" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      customer = %{ id: Ecto.UUID.generate() }
      CRMServiceMock
      |> expect(:get_customer, fn(_, _) ->
          customer
         end)

      ServiceMock
      |> expect(:list_card, fn(fields, opts) ->
          assert fields[:filter][:status] == "saved_by_owner"
          assert fields[:filter][:owner_type] == "Customer"
          assert fields[:filter][:owner_id] == customer.id
          assert opts[:account] == request.account

          [%Payment{}]
         end)
      |> expect(:count_card, fn(fields, opts) ->
          assert fields[:filter][:status] == "saved_by_owner"
          assert fields[:filter][:owner_type] == "Customer"
          assert fields[:filter][:owner_id] == customer.id
          assert opts[:account] == request.account

          1
         end)
      |> expect(:count_card, fn(fields, opts) ->
          assert fields[:filter][:status] == "saved_by_owner"
          assert fields[:filter][:owner_type] == "Customer"
          assert fields[:filter][:owner_id] == customer.id
          assert opts[:account] == request.account

          1
         end)

      {:ok, response} = Balance.list_card(request)

      assert length(response.data) == 1
      assert response.meta.all_count == 1
      assert response.meta.total_count == 1
    end

    test "when role is administrator" do
      account = %Account{}
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator"
      }

      ServiceMock
      |> expect(:list_card, fn(fields, opts) ->
          assert fields[:filter][:status] == "saved_by_owner"
          assert opts[:account] == request.account

          [%Card{}]
         end)
      |> expect(:count_card, fn(fields, opts) ->
          assert fields[:filter][:status] == "saved_by_owner"
          assert opts[:account] == request.account

          1
         end)
      |> expect(:count_card, fn(fields, opts) ->
          assert fields[:filter][:status] == "saved_by_owner"
          assert opts[:account] == request.account

          1
         end)

      {:ok, response} = Balance.list_card(request)

      assert length(response.data) == 1
      assert response.meta.all_count == 1
      assert response.meta.total_count == 1
    end
  end

  describe "update_card/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: nil,
        role: "guest"
      }

      {:error, error} = Balance.update_card(request)
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "customer",
        params: %{ "id" => Ecto.UUID.generate(), },
        fields: %{ "exp_month" => 9, "exp_year" => 2025 }
      }

      ServiceMock
      |> expect(:update_card, fn(identifiers, fields, opts) ->
          assert identifiers[:id] == request.params["id"]
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, %Card{}}
         end)

      {:ok, _} = Balance.update_card(request)
    end
  end

  describe "delete_card/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: nil,
        role: "guest"
      }

      {:error, error} = Balance.delete_card(request)
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}

      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "customer",
        params: %{ "id" => Ecto.UUID.generate() }
      }

      ServiceMock
      |> expect(:delete_card, fn(identifiers, opts) ->
          assert identifiers[:id] == request.params["id"]
          assert opts[:account] == account

          {:ok, %Card{}}
         end)

      {:ok, _} = Balance.delete_card(request)
    end
  end

  #
  # MARK: Payment
  #
  describe "list_payment/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: nil,
        role: "guest"
      }

      {:error, error} = Balance.list_payment(request)
      assert error == :access_denied
    end

    test "when role is customer" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      customer = %{ id: Ecto.UUID.generate() }
      CRMServiceMock
      |> expect(:get_customer, fn(_, _) ->
          customer
         end)

      ServiceMock
      |> expect(:list_payment, fn(fields, opts) ->
          assert fields[:filter][:owner_type] == "Customer"
          assert fields[:filter][:owner_id] == customer.id
          assert opts[:account] == request.account

          [%Payment{}]
         end)
      |> expect(:count_payment, fn(fields, opts) ->
          assert fields[:filter][:owner_type] == "Customer"
          assert fields[:filter][:owner_id] == customer.id
          assert opts[:account] == request.account

          1
         end)
      |> expect(:count_payment, fn(fields, opts) ->
          assert fields[:filter][:owner_type] == "Customer"
          assert fields[:filter][:owner_id] == customer.id
          assert opts[:account] == request.account

          1
         end)

      {:ok, response} = Balance.list_payment(request)

      assert length(response.data) == 1
      assert response.meta.all_count == 1
      assert response.meta.total_count == 1
    end

    test "when role is administrator" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "administrator"
      }

      ServiceMock
      |> expect(:list_payment, fn(_, opts) ->
          assert opts[:account] == request.account

          [%Payment{}]
         end)
      |> expect(:count_payment, fn(_, opts) ->
          assert opts[:account] == request.account

          1
         end)
      |> expect(:count_payment, fn(_, opts) ->
          assert opts[:account] == request.account

          1
         end)

      {:ok, response} = Balance.list_payment(request)

      assert length(response.data) == 1
      assert response.meta.all_count == 1
      assert response.meta.total_count == 1
    end
  end

  describe "create_payment/1" do
    test "when request is valid" do
      request = %ContextRequest{
        account: %Account{},
        user: nil,
        role: "guest"
      }

      ServiceMock
      |> expect(:create_payment, fn(_, _) ->
          {:ok, %Payment{}}
         end)

      {:ok, _} = Balance.create_payment(request)
    end
  end

  describe "get_payment/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: nil,
        role: "guest"
      }

      {:error, error} = Balance.get_payment(request)
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "customer",
        params: %{ "id" => Ecto.UUID.generate(), }
      }

      ServiceMock
      |> expect(:get_payment, fn(identifiers, opts) ->
          assert identifiers[:id] == request.params["id"]
          assert opts[:account] == account

          {:ok, %Payment{}}
         end)

      {:ok, _} = Balance.get_payment(request)
    end
  end

  describe "update_payment/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, error} = Balance.update_payment(request)
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator",
        params: %{ "id" => Ecto.UUID.generate() },
        fields: %{ "capture" => true, "capture_amount_cents" => 300 }
      }

      ServiceMock
      |> expect(:update_payment, fn(identifiers, fields, opts) ->
          assert identifiers[:id] == request.params["id"]
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, %Payment{}}
         end)

      {:ok, _} = Balance.update_payment(request)
    end
  end

  describe "delete_payment/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, error} = Balance.delete_payment(request)
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator",
        params: %{ "id" => Ecto.UUID.generate() },
      }

      ServiceMock
      |> expect(:delete_payment, fn(identifiers, opts) ->
          assert identifiers[:id] == request.params["id"]
          assert opts[:account] == account

          {:ok, %Payment{}}
         end)

      {:ok, _} = Balance.delete_payment(request)
    end
  end

  #
  # MARK: Refund
  #
  describe "create_refund/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, error} = Balance.create_refund(request)
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator",
        fields: %{
          "gateway" => "freshcom",
          "processor" => "stripe",
          "amount_cents" => 5000
        }
      }

      ServiceMock
      |> expect(:create_refund, fn(fields, opts) ->
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, %Refund{}}
         end)

      {:ok, _} = Balance.create_refund(request)
    end
  end
end
