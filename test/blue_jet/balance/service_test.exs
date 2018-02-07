defmodule BlueJet.Balance.ServiceTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity.Account
  alias BlueJet.Balance.{Settings, Card, Payment}
  alias BlueJet.Balance.Service
  alias BlueJet.Balance.{StripeClientMock, OauthClientMock}

  describe "get_settings/1" do
    test "when given id" do
      account = Repo.insert!(%Account{})
      Repo.insert!(%Settings{
        account_id: account.id
      })

      assert Service.get_settings(%{ account: account })
    end
  end

  describe "update_settings/2" do
    test "when given nil for settings" do
      {:error, error} = Service.update_settings(nil, %{}, %{})
      assert error == :not_found
    end

    test "when given settings and valid fields" do
      account = Repo.insert!(%Account{})
      settings = Repo.insert!(%Settings{
        account_id: account.id
      })

      OauthClientMock
      |> expect(:post, fn(_, _) -> {:ok, %{}} end)

      fields = %{
        "stripe_auth_code" => Faker.String.base64(5)
      }

      {:ok, settings} = Service.update_settings(settings, fields, %{ account: account })

      verify!()
      assert settings
    end
  end

  describe "list_card/2" do
    test "file for different account is not returned" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      Repo.insert!(%Card{ account_id: account.id, status: "saved_by_owner" })
      Repo.insert!(%Card{ account_id: account.id, status: "saved_by_owner" })
      Repo.insert!(%Card{ account_id: other_account.id, status: "saved_by_owner" })

      cards = Service.list_card(%{ account: account })
      assert length(cards) == 2
    end

    test "pagination should change result size" do
      account = Repo.insert!(%Account{})
      Repo.insert!(%Card{
        account_id: account.id,
        status: "saved_by_owner"
      })
      Repo.insert!(%Card{
        account_id: account.id,
        status: "saved_by_owner"
      })
      Repo.insert!(%Card{
        account_id: account.id,
        status: "saved_by_owner"
      })
      Repo.insert!(%Card{
        account_id: account.id,
        status: "saved_by_owner"
      })
      Repo.insert!(%Card{
        account_id: account.id,
        status: "saved_by_owner"
      })

      files = Service.list_card(%{ account: account, pagination: %{ size: 3, number: 1 } })
      assert length(files) == 3

      files = Service.list_card(%{ account: account, pagination: %{ size: 3, number: 2 } })
      assert length(files) == 2
    end
  end

  describe "count_card/2" do
    test "card for different account is not returned" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      Repo.insert!(%Card{ account_id: account.id, status: "saved_by_owner" })
      Repo.insert!(%Card{ account_id: account.id, status: "saved_by_owner" })
      Repo.insert!(%Card{ account_id: other_account.id, status: "saved_by_owner" })

      assert Service.count_card(%{ account: account }) == 2
    end

    test "only card matching filter is counted" do
      account = Repo.insert!(%Account{})
      Repo.insert!(%Account{})
      Repo.insert!(%Card{ account_id: account.id, status: "saved_by_owner" })
      Repo.insert!(%Card{ account_id: account.id, status: "saved_by_owner" })
      Repo.insert!(%Card{ account_id: account.id, status: "saved_by_owner", label: "test" })

      assert Service.count_card(%{ filter: %{ label: "test" } }, %{ account: account }) == 1
    end
  end

  describe "update_card/2" do
    test "when given nil for card" do
      {:error, error} = Service.update_card(nil, %{}, %{})
      assert error == :not_found
    end

    test "when given id does not exist" do
      account = Repo.insert!(%Account{})

      {:error, error} = Service.update_card(Ecto.UUID.generate(), %{}, %{ account: account })
      assert error == :not_found
    end

    test "when given id belongs to a different account" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      card = Repo.insert!(%Card{
        account_id: other_account.id,
        status: "saved_by_owner"
      })

      {:error, error} = Service.update_card(card.id, %{}, %{ account: account })
      assert error == :not_found
    end

    test "when given valid id and invalid fields" do
      account = Repo.insert!(%Account{})
      card = Repo.insert!(%Card{
        account_id: account.id,
        status: "saved_by_owner"
      })

      {:error, changeset} = Service.update_card(card.id, %{ "status" => nil }, %{ account: account })
      assert length(changeset.errors) > 0
    end

    test "when given valid id and valid fields" do
      account = Repo.insert!(%Account{})
      card = Repo.insert!(%Card{
        account_id: account.id,
        status: "saved_by_owner",
        exp_year: 2022,
        owner_id: Ecto.UUID.generate(),
        owner_type: "Customer"
      })

      StripeClientMock
      |> expect(:post, fn(_, _, _) -> {:ok, nil} end)

      fields = %{
        "exp_month" => 11
      }

      {:ok, card} = Service.update_card(card.id, fields, %{ account: account })

      verify!()
      assert card
    end

    test "when given card and invalid fields" do
      account = Repo.insert!(%Account{})
      card = Repo.insert!(%Card{
        account_id: account.id,
        status: "saved_by_owner"
      })

      {:error, changeset} = Service.update_card(card, %{ "status" => nil }, %{ account: account })
      assert length(changeset.errors) > 0
    end

    test "when given card and valid fields" do
      account = Repo.insert!(%Account{})
      card = Repo.insert!(%Card{
        account_id: account.id,
        status: "saved_by_owner",
        exp_year: 2022,
        owner_id: Ecto.UUID.generate(),
        owner_type: "Customer"
      })

      StripeClientMock
      |> expect(:post, fn(_, _, _) -> {:ok, nil} end)

      fields = %{
        "exp_month" => 11
      }

      {:ok, card} = Service.update_card(card, fields, %{ account: account })
      assert card
    end
  end

  describe "delete_card/2" do
    test "when given valid card" do
      account = Repo.insert!(%Account{})
      card = Repo.insert!(%Card{
        account_id: account.id,
        status: "saved_by_owner"
      })

      StripeClientMock
      |> expect(:delete, fn(_, _) -> {:ok, nil} end)

      {:ok, card} = Service.delete_card(card, %{ account: account })

      verify!()
      assert card
      refute Repo.get(Card, card.id)
    end
  end

  describe "list_payment/2" do
    test "payment for different account is not returned" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      Repo.insert!(%Payment{
        account_id: account.id,
        status: "pending",
        gateway: "freshcom",
        amount_cents: 500
      })
      Repo.insert!(%Payment{
        account_id: account.id,
        status: "pending",
        gateway: "freshcom",
        amount_cents: 500
      })
      Repo.insert!(%Payment{
        account_id: other_account.id,
        status: "pending",
        gateway: "freshcom",
        amount_cents: 500
      })

      payments = Service.list_payment(%{ account: account })
      assert length(payments) == 2
    end

    test "pagination should change result size" do
      account = Repo.insert!(%Account{})
      Repo.insert!(%Payment{
        account_id: account.id,
        status: "pending",
        gateway: "freshcom",
        amount_cents: 500
      })
      Repo.insert!(%Payment{
        account_id: account.id,
        status: "pending",
        gateway: "freshcom",
        amount_cents: 500
      })
      Repo.insert!(%Payment{
        account_id: account.id,
        status: "pending",
        gateway: "freshcom",
        amount_cents: 500
      })
      Repo.insert!(%Payment{
        account_id: account.id,
        status: "pending",
        gateway: "freshcom",
        amount_cents: 500
      })
      Repo.insert!(%Payment{
        account_id: account.id,
        status: "pending",
        gateway: "freshcom",
        amount_cents: 500
      })

      payments = Service.list_payment(%{ account: account, pagination: %{ size: 3, number: 1 } })
      assert length(payments) == 3

      payments = Service.list_payment(%{ account: account, pagination: %{ size: 3, number: 2 } })
      assert length(payments) == 2
    end
  end

  describe "create_payment/2" do
    test "when given invalid fields" do
      account = Repo.insert!(%Account{})
      fields = %{
        "gateway" => "freshcom",
        "processor" => "stripe",
        "source" => Ecto.UUID.generate()
      }

      EventHandlerMock
      |> expect(:handle_event, fn(name, _) ->
          assert name == "balance.payment.before_create"
          {:ok, nil}
         end)

      {:error, changeset} = Service.create_payment(fields, %{ account: account })

      verify!()
      assert changeset.valid? == false
    end

    test "when given valid fields" do
      account = Repo.insert!(%Account{})
      Repo.insert!(%Settings{
        account_id: account.id
      })

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

      fields = %{
        "status" => "paid",
        "gateway" => "freshcom",
        "processor" => "stripe",
        "amount_cents" => 500,
        "source" => "tok_" <> Ecto.UUID.generate()
      }

      {:ok, payment} = Service.create_payment(fields, %{ account: account })

      verify!()
      assert payment
    end
  end

  describe "get_payment/2" do
    test "when given id" do
      account = Repo.insert!(%Account{})
      payment = Repo.insert!(%Payment{
        account_id: account.id,
        status: "paid",
        gateway: "freshcom",
        amount_cents: 500
      })

      assert Service.get_payment(%{ id: payment.id }, %{ account: account })
    end

    test "when given id belongs to a different account" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      payment = Repo.insert!(%Payment{
        account_id: other_account.id,
        status: "paid",
        gateway: "freshcom",
        amount_cents: 500
      })

      refute Service.get_payment(%{ id: payment.id }, %{ account: account })
    end

    test "when give id does not exist" do
      account = Repo.insert!(%Account{})

      refute Service.get_payment(%{ id: Ecto.UUID.generate() }, %{ account: account })
    end
  end

  describe "update_payment/2" do
    test "when given nil for payment" do
      {:error, error} = Service.update_payment(nil, %{}, %{})
      assert error == :not_found
    end

    test "when given id does not exist" do
      account = Repo.insert!(%Account{})

      {:error, error} = Service.update_payment(Ecto.UUID.generate(), %{}, %{ account: account })
      assert error == :not_found
    end

    test "when given id belongs to a different account" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      payment = Repo.insert!(%Payment{
        account_id: other_account.id,
        status: "paid",
        gateway: "freshcom",
        amount_cents: 500
      })

      {:error, error} = Service.update_payment(payment.id, %{}, %{ account: account })
      assert error == :not_found
    end

    test "when given valid id and valid fields" do
      account = Repo.insert!(%Account{})
      payment = Repo.insert!(%Payment{
        account_id: account.id,
        status: "authorized",
        gateway: "freshcom",
        processor: "stripe",
        amount_cents: 500
      })

      StripeClientMock
      |> expect(:post, fn(_, _, _) -> {:ok, nil} end)

      EventHandlerMock
      |> expect(:handle_event, fn(name, _) ->
          assert name == "balance.payment.after_update"
          {:ok, nil}
         end)

      fields = %{
        "capture" => true,
        "capture_amount_cents" => 300
      }

      {:ok, payment} = Service.update_payment(payment.id, fields, %{ account: account })

      verify!()
      assert payment
    end
  end

  describe "delete_payment/2" do
    test "when given valid payment" do
      account = Repo.insert!(%Account{})
      payment = Repo.insert!(%Payment{
        account_id: account.id,
        status: "paid",
        gateway: "custom",
        amount_cents: 500
      })

      {:ok, payment} = Service.delete_payment(payment, %{ account: account })

      assert payment
      refute Repo.get(Payment, payment.id)
    end
  end

  describe "create_refund/2" do
    test "when given invalid fields" do
      account = Repo.insert!(%Account{})
      fields = %{}

      {:error, changeset} = Service.create_refund(fields, %{ account: account })

      verify!()
      assert changeset.valid? == false
    end

    test "when given valid fields" do
      account = Repo.insert!(%Account{})
      payment = Repo.insert!(%Payment{
        account_id: account.id,
        status: "paid",
        gateway: "freshcom",
        amount_cents: 5000,
        gross_amount_cents: 5000
      })

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

      fields = %{
        "payment_id" => payment.id,
        "gateway" => "freshcom",
        "processor" => "stripe",
        "amount_cents" => 500
      }

      {:ok, refund} = Service.create_refund(fields, %{ account: account })

      verify!()
      assert refund
    end
  end
end
