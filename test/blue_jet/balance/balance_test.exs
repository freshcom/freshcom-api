defmodule BlueJet.BalanceTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity.{Account, User}
  alias BlueJet.Balance
  alias BlueJet.Balance.{Card, Payment, Refund}
  alias BlueJet.Balance.{CrmServiceMock}
  alias BlueJet.Balance.ServiceMock

  describe "list_card/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Balance.list_card(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        filter: %{
          owner_id: Ecto.UUID.generate(),
          owner_type: "Customer"
        }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      ServiceMock
      |> expect(:list_card, fn(params, opts) ->
          assert params[:filter][:status] == "saved_by_owner"
          assert params[:filter][:owner_id] == request.filter[:owner_id]
          assert params[:filter][:owner_type] == request.filter[:owner_type]
          assert opts[:account] == account

          [%Card{}]
         end)
      |> expect(:count_card, fn(params, opts) ->
          assert params[:filter][:status] == "saved_by_owner"
          assert params[:filter][:owner_id] == request.filter[:owner_id]
          assert params[:filter][:owner_type] == request.filter[:owner_type]
          assert opts[:account] == account

          1
         end)
      |> expect(:count_card, fn(params, opts) ->
          assert params[:filter][:status] == "saved_by_owner"
          assert params[:filter][:owner_id] == nil
          assert params[:filter][:owner_type] == nil
          assert opts[:account] == account

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
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Balance.update_card(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      card = %Card{}

      request = %AccessRequest{
        account: account,
        params: %{ "id" => Ecto.UUID.generate(), },
        fields: %{ "exp_month" => 9, "exp_year" => 2025 }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:update_card, fn(id, fields, opts) ->
          assert id == request.params["id"]
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, card}
         end)

      {:ok, response} = Balance.update_card(request)

      assert response.data == card
    end

    test "when request is invalid" do
      account = %Account{}

      request = %AccessRequest{
        account: account,
        params: %{ "id" => Ecto.UUID.generate(), },
        fields: %{ "exp_month" => 9, "exp_year" => 2025 }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:update_card, fn(id, fields, opts) ->
          assert id == request.params["id"]
          assert fields == request.fields
          assert opts[:account] == account

          {:error, %{ errors: "errors" }}
         end)

      {:error, response} = Balance.update_card(request)

      assert response.errors == "errors"
    end
  end

  describe "delete_card/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Balance.delete_card(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      card = %Card{}

      request = %AccessRequest{
        account: account,
        params: %{ "id" => card.id, }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      ServiceMock
      |> expect(:delete_card, fn(id, opts) ->
          assert id == request.params["id"]
          assert opts[:account] == account

          {:ok, card}
         end)

      {:ok, _} = Balance.delete_card(request)
    end
  end

  describe "list_payment/1" do
    test "when role is not authorized" do
      request = %AccessRequest{
        account: %Account{},
        user: nil,
        role: "guest"
      }

      {:error, error} = Balance.list_payment(request)
      assert error == :access_denied
    end

    test "when role is customer" do
      request = %AccessRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      customer = %{ id: Ecto.UUID.generate() }
      CrmServiceMock
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
      request = %AccessRequest{
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
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Balance.create_payment(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is invalid" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        fields: %{
          "status" => "paid",
          "gateway" => "freshcom",
          "processor" => "stripe",
          "source" => Ecto.UUID.generate()
        }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:create_payment, fn(fields, opts) ->
          assert fields == request.fields
          assert opts[:account] == account

          {:error, %{ errors: "errors" }}
         end)

      {:error, response} = Balance.create_payment(request)

      assert response.errors == "errors"
    end

    test "when request is valid" do
      account = %Account{}
      payment = %Payment{}
      request = %AccessRequest{
        account: account,
        fields: %{
          "status" => "paid",
          "gateway" => "freshcom",
          "processor" => "stripe",
          "amount_cents" => 500,
          "source" => "tok_" <> Faker.String.base64(12)
        }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:create_payment, fn(fields, opts) ->
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, payment}
         end)

      {:ok, response} = Balance.create_payment(request)

      assert response.data == payment
    end
  end

  describe "get_payment/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Balance.get_payment(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      payment = %Payment{}
      request = %AccessRequest{
        account: account,
        params: %{ "id" => Ecto.UUID.generate() }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:get_payment, fn(identifiers, opts) ->
          assert identifiers[:id] == request.params["id"]
          assert opts[:account] == account

          payment
         end)

      {:ok, response} = Balance.get_payment(request)

      assert response.data == payment
    end
  end

  describe "update_payment/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Balance.update_payment(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      payment = %Payment{}
      request = %AccessRequest{
        role: "developer",
        account: account,
        params: %{ "id" => Ecto.UUID.generate(), },
        fields: %{ "capture" => true, "capture_amount_cents" => 300 }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:update_payment, fn(id, fields, opts) ->
          assert id == request.params["id"]
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, payment}
         end)

      {:ok, response} = Balance.update_payment(request)

      assert response.data == payment
    end

    test "when request is invalid" do
      account = %Account{}
      request = %AccessRequest{
        role: "developer",
        account: account,
        params: %{ "id" => Ecto.UUID.generate(), },
        fields: %{ "capture" => true, "capture_amount_cents" => 300 }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:update_payment, fn(id, fields, opts) ->
          assert id == request.params["id"]
          assert fields == request.fields
          assert opts[:account] == account

          {:error, %{ errors: "errors" }}
         end)

      {:error, response} = Balance.update_payment(request)

      assert response.errors == "errors"
    end
  end

  describe "create_refund/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Balance.create_refund(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      refund = %Refund{}
      request = %AccessRequest{
        role: "customer",
        account: account,
        params: %{
          "payment_id" => Ecto.UUID.generate()
        },
        fields: %{
          "gateway" => "freshcom",
          "processor" => "stripe",
          "amount_cents" => 5000
        }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      ServiceMock
      |> expect(:create_refund, fn(fields, opts) ->
          assert fields["payment_id"] == request.params["payment_id"]
          assert opts[:account] == account

          {:ok, refund}
         end)

      {:ok, response} = Balance.create_refund(request)

      assert response.data == refund
    end
  end
end
