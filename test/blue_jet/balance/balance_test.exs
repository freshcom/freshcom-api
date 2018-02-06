defmodule BlueJet.BalanceTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity.Account
  alias BlueJet.Balance
  alias BlueJet.Balance.{Card, Payment, Settings}
  alias BlueJet.Balance.{StripeClientMock}

  setup :verify_on_exit!

  describe "list_card/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Balance.list_card(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = Repo.insert!(%Account{})
      Repo.insert!(%Card{
        account_id: account.id,
        status: "saved_by_owner"
      })

      request = %AccessRequest{
        role: "developer",
        account: account
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

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
      account = Repo.insert!(%Account{})
      card = Repo.insert!(%Card{
        account_id: account.id,
        status: "saved_by_owner",
        owner_id: Ecto.UUID.generate(),
        owner_type: "Customer"
      })

      request = %AccessRequest{
        role: "developer",
        account: account,
        params: %{ "id" => card.id, },
        fields: %{ "exp_month" => 9, "exp_year" => 2025 }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      StripeClientMock
      |> expect(:post, fn(_, _, _) -> {:ok, nil} end)

      {:ok, response} = Balance.update_card(request)
      assert response.data.id == card.id
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
      account = Repo.insert!(%Account{})
      card = Repo.insert!(%Card{
        account_id: account.id,
        status: "saved_by_owner"
      })

      request = %AccessRequest{
        role: "developer",
        account: account,
        params: %{ "id" => card.id, }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      StripeClientMock
      |> expect(:delete, fn(_, _) -> {:ok, nil} end)

      {:ok, _} = Balance.delete_card(request)
    end
  end

  describe "list_payment/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Balance.list_payment(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = Repo.insert!(%Account{})
      Repo.insert!(%Payment{
        account_id: account.id,
        gateway: "online",
        amount_cents: 500
      })

      request = %AccessRequest{
        role: "developer",
        account: account
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

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

    test "when request has errors" do
      account = Repo.insert!(%Account{})
      request = %AccessRequest{
        role: "customer",
        account: account,
        fields: %{
          "gateway" => "freshcom",
          "processor" => "stripe",
          "source" => Ecto.UUID.generate()
        }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      EventHandlerMock
      |> expect(:handle_event, fn(name, _) ->
          assert name == "balance.payment.before_create"
          {:ok, nil}
         end)

      {:error, response} = Balance.create_payment(request)

      assert Keyword.keys(response.errors) == [:amount_cents]
    end

    test "when request is valid" do
      account = Repo.insert!(%Account{})
      Repo.insert!(%Settings{
        account_id: account.id
      })

      request = %AccessRequest{
        role: "customer",
        account: account,
        fields: %{
          "gateway" => "freshcom",
          "processor" => "stripe",
          "amount_cents" => 500,
          "source" => "tok_" <> Faker.String.base64(12)
        }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      stripe_charge_id = Faker.String.base64(12)
      stripe_transfer_id = Faker.String.base64(12)
      stripe_charge = %{
        "captured" => true,
        "id" => stripe_charge_id,
        "amount" => 500,
        "balance_transaction" => %{
          "fee" => 50
        },
        "transfer" => %{
          "id" => stripe_transfer_id,
          "amount" => 400
        }
      }
      StripeClientMock
      |> expect(:post, fn(_, _, _) -> {:ok, stripe_charge} end)

      EventHandlerMock
      |> expect(:handle_event, fn(name, _) ->
          assert name == "balance.payment.before_create"
          {:ok, nil}
         end)
      |> expect(:handle_event, fn(name, _) ->
          assert name == "balance.payment.after_create"
          {:ok, nil}
         end)

      {:ok, response} = Balance.create_payment(request)

      assert response.data.stripe_charge_id == stripe_charge_id
      assert response.data.stripe_transfer_id == stripe_transfer_id
      assert response.data.amount_cents == 500
      assert response.data.gateway == "freshcom"
      assert response.data.processor == "stripe"
      assert response.data.processor_fee_cents == 50
      assert response.data.freshcom_fee_cents == 50
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
      account = Repo.insert!(%Account{})
      payment = Repo.insert!(%Payment{
        account_id: account.id,
        gateway: "online",
        amount_cents: 500
      })

      request = %AccessRequest{
        role: "developer",
        account: account,
        params: %{ "id" => payment.id }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, response} = Balance.get_payment(request)
      assert response.data.id == payment.id
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
      account = Repo.insert!(%Account{})
      payment = Repo.insert!(%Payment{
        account_id: account.id,
        status: "authorized",
        gateway: "freshcom",
        processor: "stripe",
        amount_cents: 500
      })

      request = %AccessRequest{
        role: "developer",
        account: account,
        params: %{ "id" => payment.id, },
        fields: %{ "capture" => true, "capture_amount_cents" => 300 }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      StripeClientMock
      |> expect(:post, fn(_, _, _) -> {:ok, nil} end)

      EventHandlerMock
      |> expect(:handle_event, fn(name, _) ->
          assert name == "balance.payment.after_update"
          {:ok, nil}
         end)

      {:ok, response} = Balance.update_payment(request)
      assert response.data.id == payment.id
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
      account = Repo.insert!(%Account{})
      payment = Repo.insert!(%Payment{
        account_id: account.id,
        gateway: "online",
        amount_cents: 5000,
        gross_amount_cents: 5000
      })

      request = %AccessRequest{
        role: "customer",
        account: account,
        params: %{
          "payment_id" => payment.id
        },
        fields: %{
          "gateway" => "online",
          "processor" => "stripe",
          "amount_cents" => 5000
        }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      stripe_refund_id = Faker.String.base64(12)
      stripe_refund = %{
        "id" => stripe_refund_id,
        "balance_transaction" => %{
          "fee" => -500
        }
      }
      stripe_transfer_reversal_id = Faker.String.base64(12)
      stripe_transfer_reversal = %{
        "id" => stripe_transfer_reversal_id,
        "amount" => 4200
      }
      StripeClientMock
      |> expect(:post, fn(_, _, _) -> {:ok, stripe_refund} end)
      |> expect(:post, fn(_, _, _) -> {:ok, stripe_transfer_reversal} end)

      EventHandlerMock
      |> expect(:handle_event, fn(name, _) ->
          assert name == "balance.refund.after_create"
          {:ok, nil}
         end)

      {:ok, response} = Balance.create_refund(request)

      assert response.data
    end
  end
end
