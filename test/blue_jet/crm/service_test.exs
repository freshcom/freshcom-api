defmodule BlueJet.CRM.ServiceTest do
  use BlueJet.DataCase

  import BlueJet.CRM.TestHelper

  alias BlueJet.Identity.Account
  alias BlueJet.CRM.{Customer}
  alias BlueJet.CRM.Service

  #
  # MARK: Customer
  #
  describe "list_customer/2 and count_customer/2" do
    test "with valid query" do
      account1 = account_fixture()
      account2 = account_fixture()

      customer_fixture(account1, %{label: "group1", name: "Awesome Guy"})
      customer_fixture(account1, %{label: "group1", name: "Handsome Guy"})
      customer_fixture(account1, %{label: "group1", name: "Good Guy"})
      customer_fixture(account1, %{name: "Handsome Guy"})
      customer_fixture(account1)
      customer_fixture(account1)

      customer_fixture(account2, %{label: "group1", name: "Awesome Guy"})

      query = %{
        filter: %{label: "group1"},
        search: "guy"
      }

      customers = Service.list_customer(query, %{
        account: account1,
        pagination: %{size: 2, number: 1}
      })

      assert length(customers) == 2

      customers = Service.list_customer(query, %{
        account: account1,
        pagination: %{size: 2, number: 2}
      })

      assert length(customers) == 1

      assert Service.count_customer(query, %{account: account1}) == 3
      assert Service.count_customer(%{account: account1}) == 6
    end
  end

  describe "create_customer/2" do
    test "when given invalid fields" do
      account = account_fixture()
      fields = %{"status" => "registered"}

      {:error, %{errors: errors}} = Service.create_customer(fields, %{account: account})

      assert match_keys(errors, [:name, :username, :password])
    end

    test "when given fields has no status" do
      account = account_fixture()

      {:ok, _} = Service.create_customer(%{}, %{account: account})
    end

    test "when given valid fields" do
      account = account_fixture()
      fields = %{
        "status" => "registered",
        "name" => Faker.Name.name(),
        "email" => Faker.Internet.safe_email(),
        "password" => "test1234"
      }

      EventHandlerMock
      |> expect(:handle_event, fn(name, data) ->
          assert name == "identity:user.create.success"
          assert match_keys(data, [:user, :account])

          {:ok, nil}
         end)
      |> expect(:handle_event, fn(name, data) ->
          assert name == "identity:email_verification_token.create.success"
          assert match_keys(data, [:user])

          {:ok, nil}
         end)

      {:ok, customer} = Service.create_customer(fields, %{account: account})

      assert customer.status == fields["status"]
      assert customer.name == fields["name"]
      assert customer.email == fields["email"]
      assert customer.account_id == account.id
    end
  end

  describe "get_customer/2" do
    test "when give id does not exist" do
      account = %Account{id: UUID.generate()}

      refute Service.get_customer(%{id: UUID.generate()}, %{account: account})
    end

    test "when given id belongs to a different account" do
      account1 = account_fixture()
      account2 = account_fixture()

      customer = customer_fixture(account1)

      refute Service.get_customer(%{id: customer.id}, %{account: account2})
    end

    test "when some identifiers doesn't match" do
      account = account_fixture()
      target_customer = customer_fixture(account)

      refute Service.get_customer(%{id: target_customer.id, email: "invalid"}, %{account: account})
    end

    test "when given valid id" do
      account = account_fixture()
      target_customer = customer_fixture(account)

      customer = Service.get_customer(%{id: target_customer.id}, %{account: account})

      assert customer.id == target_customer.id
    end

    test "when given multiple valid identifiers" do
      account = account_fixture()
      target_customer = customer_fixture(account, %{code: "code123"})
      identifiers = %{code: target_customer.code, email: target_customer.email, name: target_customer.name}

      customer = Service.get_customer(identifiers, %{account: account})

      assert customer.id == target_customer.id
    end
  end

  describe "update_customer/3" do
    test "when given id does not exist" do
      account = account_fixture()

      identifiers = %{id: UUID.generate()}
      opts = %{account: account}
      {:error, error} = Service.update_customer(identifiers, %{}, opts)

      assert error == :not_found
    end

    test "when given id belongs to a different account" do
      account1 = account_fixture()
      account2 = account_fixture()
      customer = customer_fixture(account1)

      identifiers = %{id: customer.id}
      opts = %{account: account2}

      {:error, error} = Service.update_customer(identifiers, %{}, opts)

      assert error == :not_found
    end

    test "when given valid id and valid fields" do
      account = account_fixture()
      target_customer = customer_fixture(account)

      identifiers = %{id: target_customer.id}
      fields = %{"name" => Faker.Name.name()}
      opts = %{account: account}

      {:ok, customer} = Service.update_customer(identifiers, fields, opts)

      assert customer.name == fields["name"]
    end
  end

  describe "delete_customer/2" do
    test "when given id does not exist" do
      account = account_fixture()

      identifiers = %{id: UUID.generate()}
      opts = %{account: account}

      {:error, error} = Service.delete_customer(identifiers, opts)

      assert error == :not_found
    end

    test "when given id belongs to a different account" do
      account1 = account_fixture()
      account2 = account_fixture()
      customer = customer_fixture(account1)

      identifiers = %{id: customer.id}
      opts = %{account: account2}

      {:error, error} = Service.delete_customer(identifiers, opts)

      assert error == :not_found
    end

    test "when given valid id" do
      account = account_fixture()
      customer = customer_fixture(account)

      identifiers = %{id: customer.id}
      opts = %{account: account}

      {:ok, customer} = Service.delete_customer(identifiers, opts)

      assert customer
      refute Repo.get(Customer, customer.id)
    end
  end

  describe "delete_all_customer/1" do
    test "given valid account" do
      account = account_fixture()
      test_account = account.test_account
      customer1 = customer_fixture(test_account)
      customer2 = customer_fixture(test_account)

      :ok = Service.delete_all_customer(%{account: test_account})

      refute Repo.get(Customer, customer1.id)
      refute Repo.get(Customer, customer2.id)
    end
  end

  #
  # MARK: Point Account
  #
  describe "get_point_account/2" do
    test "when give id does not exist" do
      account = %Account{id: UUID.generate()}

      refute Service.get_point_account(%{id: UUID.generate()}, %{account: account})
    end

    test "when given id belongs to a different account" do
      account1 = account_fixture()
      account2 = account_fixture()

      customer = customer_fixture(account1)

      refute Service.get_point_account(%{id: customer.point_account.id}, %{account: account2})
    end

    test "when given valid id" do
      account = account_fixture()
      customer = customer_fixture(account)

      identifiers = %{id: customer.point_account.id}
      opts = %{account: account}

      point_account = Service.get_point_account(identifiers, opts)

      assert point_account.id == customer.point_account.id
    end
  end

  #
  # MARK: Point Transaction
  #
  describe "list_point_transaction/2 and count_point_transaction/2" do
    test "with valid query" do
      account1 = account_fixture()
      account2 = account_fixture()
      point_account1 = customer_fixture(account1).point_account
      point_account2 = customer_fixture(account2).point_account

      point_transaction_fixture(account1, point_account1, %{status: "committed", name: "Awesome Guy"})
      point_transaction_fixture(account1, point_account1, %{status: "committed", name: "Handsome Guy"})
      point_transaction_fixture(account1, point_account1, %{status: "committed", name: "Good Guy"})
      point_transaction_fixture(account1, point_account1, %{name: "Handsome Guy"})
      point_transaction_fixture(account1, point_account1)
      point_transaction_fixture(account1, point_account1)

      point_transaction_fixture(account2, point_account2, %{status: "committed", name: "Awesome Guy"})

      query = %{
        filter: %{status: "committed"},
        search: "guy"
      }

      point_transactions = Service.list_point_transaction(query, %{
        account: account1,
        pagination: %{size: 2, number: 1}
      })

      assert length(point_transactions) == 2

      point_transactions = Service.list_point_transaction(query, %{
        account: account1,
        pagination: %{size: 2, number: 2}
      })

      assert length(point_transactions) == 1

      assert Service.count_point_transaction(query, %{account: account1}) == 3
      assert Service.count_point_transaction(%{account: account1}) == 6
    end
  end

  describe "create_point_transaction/2" do
    test "when given invalid fields" do
      account = account_fixture()
      fields = %{}

      {:error, %{errors: errors}} = Service.create_point_transaction(fields, %{account: account})

      assert match_keys(errors, [:amount])
    end

    test "when given status is pending" do
      account = account_fixture()
      customer = customer_fixture(account)
      point_account = customer.point_account

      fields = %{
        "point_account_id" => point_account.id,
        "amount" => System.unique_integer([:positive])
      }

      {:ok, point_transaction} = Service.create_point_transaction(fields, %{account: account})
      point_account = Service.get_point_account(%{id: point_account.id}, %{account: account})

      assert point_transaction.status == "pending"
      assert point_transaction.amount == fields["amount"]
      assert point_transaction.point_account_id == point_account.id
      assert point_transaction.account_id == account.id
      assert point_transaction.balance_after_commit == nil
      assert point_account.balance == 0
    end

    test "when given status is committed" do
      account = account_fixture()
      customer = customer_fixture(account)
      point_account = customer.point_account

      fields = %{
        "status" => "committed",
        "point_account_id" => point_account.id,
        "amount" => System.unique_integer([:positive])
      }

      {:ok, point_transaction} = Service.create_point_transaction(fields, %{account: account})
      point_account = Service.get_point_account(%{id: point_account.id}, %{account: account})

      assert point_transaction.status == "committed"
      assert point_transaction.amount == fields["amount"]
      assert point_transaction.point_account_id == point_account.id
      assert point_transaction.account_id == account.id
      assert point_transaction.balance_after_commit == point_transaction.amount
      assert point_account.balance == point_transaction.amount
    end
  end

  describe "update_point_transaction/3" do
    test "when given invalid identifiers" do
      account = %Account{id: UUID.generate()}

      identifiers = %{id: UUID.generate()}
      fields = %{}
      opts = %{account: account}

      {:error, :not_found} = Service.update_point_transaction(identifiers, fields, opts)
    end

    test "when given invalid fields" do
      account = account_fixture()
      customer = customer_fixture(account)
      transaction = point_transaction_fixture(account, customer.point_account)

      identifiers = %{id: transaction.id}
      fields = %{status: nil}
      opts = %{account: account}

      {:error, %{errors: errors}} = Service.update_point_transaction(identifiers, fields, opts)

      assert match_keys(errors, [:status])
    end

    test "when updating status to committed" do
      account = account_fixture()
      customer = customer_fixture(account)
      point_account = customer.point_account
      target_transaction = point_transaction_fixture(account, point_account)

      identifiers = %{id: target_transaction.id}
      fields = %{"status" => "committed"}
      opts = %{account: account}

      {:ok, transaction} = Service.update_point_transaction(identifiers, fields, opts)
      point_account = Service.get_point_account(%{id: point_account.id}, %{account: account})

      assert transaction.status == "committed"
      assert transaction.amount == target_transaction.amount
      assert transaction.balance_after_commit == point_account.balance
      assert point_account.balance == transaction.amount
    end

    test "when updating fields other than status" do
      account = account_fixture()
      customer = customer_fixture(account)
      point_account = customer.point_account
      target_transaction = point_transaction_fixture(account, point_account)

      identifiers = %{id: target_transaction.id}
      fields = %{"description" => "description"}
      opts = %{account: account}

      {:ok, transaction} = Service.update_point_transaction(identifiers, fields, opts)
      point_account = Service.get_point_account(%{id: point_account.id}, %{account: account})

      assert transaction.status == "pending"
      assert transaction.amount == target_transaction.amount
      assert transaction.balance_after_commit == nil
      assert point_account.balance == 0
    end
  end

  describe "delete_point_transaction/2" do
    test "when given id does not exist" do
      account = account_fixture()

      identifiers = %{id: UUID.generate()}
      opts = %{account: account}

      {:error, :not_found} = Service.delete_point_transaction(identifiers, opts)
    end

    test "when status is committed" do
      account = account_fixture()
      customer = customer_fixture(account)
      transaction = point_transaction_fixture(account, customer.point_account, %{status: "committed"})

      identifiers = %{id: transaction.id}
      opts = %{account: account}

      {:error, :not_found} = Service.delete_point_transaction(identifiers, opts)
    end

    test "when status is pending" do
      account = account_fixture()
      customer = customer_fixture(account)
      transaction = point_transaction_fixture(account, customer.point_account)

      identifiers = %{id: transaction.id}
      opts = %{account: account}

      {:ok, _} = Service.delete_point_transaction(identifiers, opts)
    end
  end
end
