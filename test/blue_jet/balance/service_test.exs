defmodule BlueJet.Balance.ServiceTest do
  use BlueJet.ContextCase

  import BlueJet.Balance.TestHelper
  import BlueJet.CRM.TestHelper

  alias BlueJet.Identity.Account
  alias BlueJet.Balance.{Card, Payment}
  alias BlueJet.Balance.{StripeClientMock, OauthClientMock}
  alias BlueJet.Balance.Service

  describe "get_settings/1" do
    test "when given id" do
      account = account_fixture()
      settings_fixture(account)

      assert Service.get_settings(%{account: account})
    end
  end

  describe "update_settings/2" do
    test "when given nil for settings" do
      {:error, error} = Service.update_settings(nil, %{}, %{})
      assert error == :not_found
    end

    test "when given settings and valid fields" do
      account = account_fixture()
      settings = settings_fixture(account)

      stripe_response = %{
        "stripe_user_id" => Faker.Lorem.word(),
        "stripe_livemode" => true
      }
      OauthClientMock
      |> expect(:post, fn(_, _) -> {:ok, stripe_response} end)

      fields = %{"stripe_auth_code" => Faker.String.base64(5)}

      {:ok, settings} = Service.update_settings(settings, fields, %{account: account})

      assert settings.stripe_user_id == stripe_response["stripe_user_id"]
    end
  end

  #
  # MARK: Card
  #
  describe "list_card/2 and count_card/2" do
    setup do
      account1 = account_fixture()
      account2 = account_fixture()

      card_fixture(account1, %{label: "test_card"})
      card_fixture(account1, %{label: "test_card"})
      card_fixture(account1, %{label: "test_card"})
      card_fixture(account1)
      card_fixture(account1)
      card_fixture(account1)

      card_fixture(account2, %{label: "test_card"})

      query = %{filter: %{label: "test_card"}}

      %{account: account1, query: query}
    end

    test "pagination will change the return result", %{account: account, query: query} do
      cards = Service.list_card(query, %{
        account: account,
        pagination: %{size: 2, number: 1}
      })

      assert length(cards) == 2

      cards = Service.list_card(query, %{
        account: account,
        pagination: %{size: 2, number: 2}
      })

      assert length(cards) == 1
    end

    test "count will change according to query", %{account: account, query: query} do
      assert Service.count_card(query, %{account: account}) == 3
      assert Service.count_card(%{account: account}) == 6
    end
  end

  describe "create_card/2" do
    test "when given invalid fields" do
      account = account_fixture()

      {:error, changeset} = Service.create_card(%{}, %{account: account})

      assert changeset.valid? == false
      assert match_keys(changeset.errors, [:source, :owner_id, :owner_type])
    end

    test "when given source is a stripe card with the same fingerprint of an existing card by the same owner" do
      account = account_fixture()
      existing_card = card_fixture(account, %{fingerprint: Faker.String.base64(12)})

      stripe_card = %{
        "last4" => "1231",
        "exp_month" => 10,
        "exp_year" => 2025,
        "fingerprint" => existing_card.fingerprint,
        "name" => Faker.String.base64(5),
        "brand" => "visa",
        "country" => "Canada",
        "id" => existing_card.stripe_card_id
      }

      StripeClientMock
      |> expect(:get, fn(_, _) -> {:ok, stripe_card} end)
      |> expect(:post, fn(_, _, _) -> {:ok, stripe_card} end)

      fields = %{
        status: "saved_by_owner",
        source: stripe_card["id"],
        owner_id: existing_card.owner_id,
        owner_type: existing_card.owner_type
      }

      {:ok, card} = Service.create_card(fields, %{account: account})

      assert card.id == existing_card.id
      assert card.last_four_digit == stripe_card["last4"]
      assert card.exp_month == stripe_card["exp_month"]
      assert card.exp_year == stripe_card["exp_year"]
      assert card.brand == stripe_card["brand"]
      assert card.country == stripe_card["country"]
    end

    test "when given source is a stripe token with the same fingerprint of an existing card by a different owner" do
      account = account_fixture()
      existing_card = card_fixture(account, %{fingerprint: Faker.String.base64(12)})

      stripe_card = %{
        "last4" => "1231",
        "exp_month" => 10,
        "exp_year" => 2025,
        "fingerprint" => existing_card.fingerprint,
        "name" => Faker.String.base64(5),
        "brand" => "visa",
        "country" => "Canada",
        "id" => Faker.String.base64(12)
      }
      stripe_token = %{
        "card" => stripe_card
      }

      StripeClientMock
      |> expect(:get, fn(_, _) -> {:ok, stripe_token} end)
      |> expect(:post, fn(_, _, _) -> {:ok, stripe_card} end)

      fields = %{
        status: "saved_by_owner",
        source: "tok_" <> Faker.String.base64(12),
        owner_id: UUID.generate(),
        owner_type: "Customer",
        stripe_customer_id: UUID.generate()
      }

      {:ok, card} = Service.create_card(fields, %{account: account})

      assert card.id != existing_card.id
      assert card.last_four_digit == stripe_card["last4"]
      assert card.exp_month == stripe_card["exp_month"]
      assert card.exp_year == stripe_card["exp_year"]
      assert card.brand == stripe_card["brand"]
      assert card.country == stripe_card["country"]
    end

    test "when given source is a stripe token a new fingerprint" do
      account = account_fixture()

      stripe_card = %{
        "last4" => "1231",
        "exp_month" => 10,
        "exp_year" => 2025,
        "fingerprint" => Faker.String.base64(12),
        "name" => Faker.String.base64(5),
        "brand" => "visa",
        "country" => "Canada",
        "id" => Faker.String.base64(12)
      }
      stripe_token = %{
        "card" => stripe_card
      }

      StripeClientMock
      |> expect(:get, fn(_, _) -> {:ok, stripe_token} end)
      |> expect(:post, fn(_, _, _) -> {:ok, stripe_card} end)

      fields = %{
        status: "saved_by_owner",
        source: "tok_" <> Faker.String.base64(12),
        owner_id: UUID.generate(),
        owner_type: "Customer",
        stripe_customer_id: UUID.generate()
      }

      {:ok, card} = Service.create_card(fields, %{account: account})

      assert card.last_four_digit == stripe_card["last4"]
      assert card.exp_month == stripe_card["exp_month"]
      assert card.exp_year == stripe_card["exp_year"]
      assert card.brand == stripe_card["brand"]
      assert card.country == stripe_card["country"]
    end
  end

  describe "update_card/2" do
    test "when given id does not exist" do
      account = %{id: UUID.generate()}

      {:error, :not_found} = Service.update_card(%{id: UUID.generate()}, %{}, %{account: account})
    end

    test "when given id belongs to a different account" do
      account1 = account_fixture()
      account2 = Repo.insert!(%Account{})
      card = card_fixture(account2)

      {:error, :not_found} = Service.update_card(%{id: card.id}, %{}, %{account: account1})
    end

    test "when given valid id and invalid fields" do
      account = account_fixture()
      card = card_fixture(account)

      {:error, changeset} = Service.update_card(%{id: card.id}, %{"status" => nil}, %{account: account})

      assert match_keys(changeset.errors, [:status])
    end

    test "when given valid id and valid fields" do
      account = account_fixture()
      card = card_fixture(account)

      StripeClientMock
      |> expect(:post, fn(_, _, _) -> {:ok, nil} end)

      fields = %{"exp_month" => 11}

      {:ok, card} = Service.update_card(%{id: card.id}, fields, %{account: account})

      assert card
    end
  end

  describe "delete_card/2" do
    test "when given id does not exist" do
      account = %{id: UUID.generate()}

      {:error, :not_found} = Service.delete_card(%{id: UUID.generate()}, %{account: account})
    end

    test "when given valid id" do
      account = account_fixture()
      card = card_fixture(account)

      StripeClientMock
      |> expect(:delete, fn(_, _) -> {:ok, nil} end)

      {:ok, card} = Service.delete_card(card, %{account: account})

      refute Repo.get(Card, card.id)
    end
  end

  #
  # MARK: Payment
  #
  describe "list_payment/2 and count_payment/2" do
    setup do
      account1 = account_fixture()
      account2 = account_fixture()

      payment_fixture(account1, %{label: "test_payment"})
      payment_fixture(account1, %{label: "test_payment"})
      payment_fixture(account1, %{label: "test_payment"})
      payment_fixture(account1)
      payment_fixture(account1)
      payment_fixture(account1)

      payment_fixture(account2, %{label: "test_payment"})

      query = %{filter: %{label: "test_payment"}}

      %{account: account1, query: query}
    end

    test "pagination will change the return result", %{account: account, query: query} do
      payments = Service.list_payment(query, %{
        account: account,
        pagination: %{size: 2, number: 1}
      })

      assert length(payments) == 2

      payments = Service.list_payment(query, %{
        account: account,
        pagination: %{size: 2, number: 2}
      })

      assert length(payments) == 1
    end

    test "count will change according to query", %{account: account, query: query} do
      assert Service.count_payment(query, %{account: account}) == 3
      assert Service.count_payment(%{account: account}) == 6
    end
  end

  describe "create_payment/2" do
    test "when given invalid fields" do
      account = account_fixture()

      EventHandlerMock
      |> expect(:handle_event, fn(name, _) ->
          assert name == "balance:payment.create.before"
          {:ok, nil}
         end)

      {:error, changeset} = Service.create_payment(%{}, %{account: account})

      assert match_keys(changeset.errors, [:status, :gateway, :amount_cents])
    end

    test "when given valid fields without owner" do
      account = account_fixture()
      settings_fixture(account)

      stripe_charge = %{
        "captured" => true,
        "id" => Faker.String.base64(12),
        "amount" => 500,
        "balance_transaction" => %{
          "fee" => 50
        },
        "transfer" => %{
          "id" => Faker.String.base64(12),
          "amount" => 400
        }
      }
      StripeClientMock
      |> expect(:post, fn(_, _, _) -> {:ok, stripe_charge} end)

      EventHandlerMock
      |> expect(:handle_event, fn(name, _) ->
          assert name == "balance:payment.create.before"
          {:ok, nil}
         end)
      |> expect(:handle_event, fn(name, _) ->
          assert name == "balance:payment.create.success"
          {:ok, nil}
         end)

      fields = %{
        "status" => "paid",
        "gateway" => "freshcom",
        "processor" => "stripe",
        "amount_cents" => 500,
        "source" => "tok_" <> UUID.generate()
      }

      {:ok, payment} = Service.create_payment(fields, %{account: account})

      assert payment
      assert payment.amount_cents == fields["amount_cents"]
      assert payment.status == "paid"
    end

    test "when given valid fields with owner" do
      account = account_fixture()
      customer = customer_fixture(account)
      settings_fixture(account)

      stripe_customer = %{
        "id" => Faker.String.base64(12)
      }
      stripe_card = %{
        "last4" => "1231",
        "exp_month" => 10,
        "exp_year" => 2025,
        "fingerprint" => Faker.String.base64(12),
        "name" => Faker.String.base64(5),
        "brand" => "visa",
        "country" => "Canada",
        "id" => Faker.String.base64(12)
      }
      stripe_token = %{
        "card" => stripe_card
      }
      stripe_charge = %{
        "captured" => true,
        "id" => Faker.String.base64(12),
        "amount" => 500,
        "balance_transaction" => %{
          "fee" => 50
        },
        "transfer" => %{
          "id" => Faker.String.base64(12),
          "amount" => 400
        }
      }
      StripeClientMock
      |> expect(:post, fn(_, _, _) -> {:ok, stripe_customer} end)
      |> expect(:get, fn(_, _) -> {:ok, stripe_token} end)
      |> expect(:post, fn(_, _, _) -> {:ok, stripe_card} end)
      |> expect(:post, fn(_, _, _) -> {:ok, stripe_charge} end)

      EventHandlerMock
      |> expect(:handle_event, fn(name, _) ->
          assert name == "balance:payment.create.before"
          {:ok, nil}
         end)
      |> expect(:handle_event, fn(name, _) ->
          assert name == "balance:payment.create.success"
          {:ok, nil}
         end)

      fields = %{
        "status" => "paid",
        "gateway" => "freshcom",
        "processor" => "stripe",
        "amount_cents" => 500,
        "source" => "tok_" <> UUID.generate(),
        "owner_id" => customer.id,
        "owner_type" => "Customer"
      }

      {:ok, payment} = Service.create_payment(fields, %{account: account})

      assert payment
      assert payment.amount_cents == fields["amount_cents"]
      assert payment.status == "paid"
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

      refute Service.get_payment(%{ id: UUID.generate() }, %{ account: account })
    end
  end

  describe "update_payment/2" do
    test "when given nil for payment" do
      {:error, error} = Service.update_payment(nil, %{}, %{})
      assert error == :not_found
    end

    test "when given id does not exist" do
      account = Repo.insert!(%Account{})

      {:error, error} = Service.update_payment(%{ id: UUID.generate() }, %{}, %{ account: account })
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

      {:error, error} = Service.update_payment(%{ id: payment.id }, %{}, %{ account: account })
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
          assert name == "balance:payment.update.success"
          {:ok, nil}
         end)

      fields = %{
        "capture" => true,
        "capture_amount_cents" => 300
      }

      {:ok, payment} = Service.update_payment(%{ id: payment.id }, fields, %{ account: account })

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

  #
  # MARK: Payment
  #
  describe "create_refund/2" do
    test "when given invalid fields" do
      account = Repo.insert!(%Account{})
      fields = %{}

      {:error, changeset} = Service.create_refund(fields, %{ account: account })

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
          assert name == "balance:refund.create.success"
          {:ok, nil}
         end)

      fields = %{
        "payment_id" => payment.id,
        "gateway" => "freshcom",
        "processor" => "stripe",
        "amount_cents" => 500
      }

      {:ok, refund} = Service.create_refund(fields, %{ account: account })

      assert refund
    end
  end
end
