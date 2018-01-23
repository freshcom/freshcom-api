defmodule BlueJet.OrderTest do
  use BlueJet.DataCase

  import Mox

  alias BlueJet.Identity.Account
  alias BlueJet.Crm.Customer

  alias BlueJet.Storefront.{Order, OrderLineItem}
  alias BlueJet.Storefront.{BalanceDataMock, DistributionDataMock}
  alias BlueJet.Distribution.{Fulfillment, FulfillmentLineItem}

  describe "schema" do
    test "when account is deleted order should be automatically deleted" do
      account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: account.id
      })

      Repo.delete!(account)
      refute Repo.get(Order, order.id)
    end

    test "when customer is deleted customer_id should be nilified" do
      account = Repo.insert!(%Account{})
      customer = Repo.insert!(%Customer{
        name: Faker.String.base64(5)
      })
      order = Repo.insert!(%Order{
        account_id: account.id,
        customer_id: customer.id
      })

      Repo.delete!(customer)
      order = Repo.get(Order, order.id)

      assert order.customer_id == nil
    end

    test "defaults" do
      order = %Order{}

      assert order.status == "cart"
      assert order.payment_status == "pending"
      assert order.fulfillment_status == "pending"

      assert order.sub_total_cents == 0
      assert order.tax_one_cents == 0
      assert order.tax_two_cents == 0
      assert order.tax_three_cents == 0
      assert order.grand_total_cents == 0
      assert order.authorization_total_cents == 0
      assert order.is_estimate == false
      assert order.custom_data == %{}
      assert order.translations == %{}
    end
  end

  describe "validate/1" do
    test "when given order missing required fields" do
      order =
        %Order{ id: Ecto.UUID.generate() }
        |> put_meta(state: :loaded)

      changeset =
        order
        |> change(%{})
        |> Order.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [
        :name,
        :email,
        :fulfillment_method
      ]
    end

    test "when given order have invalid email" do
      order =
        %Order{ id: Ecto.UUID.generate() }
        |> put_meta(state: :loaded)

      changeset =
        order
        |> change(%{
            name: Faker.String.base64(5),
            email: "test",
            fulfillment_method: "pickup"
           })
        |> Order.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:email]
    end

    test "when given order has unlockable" do
      account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: account.id
      })
      Repo.insert!(%OrderLineItem{
        account_id: account.id,
        order_id: order.id,
        name: Faker.String.base64(5),
        charge_quantity: 1,
        sub_total_cents: 500,
        grand_total_cents: 500,
        authorization_total_cents: 500,
        is_leaf: true,
        auto_fulfill: false,
        source_type: "Unlockable"
      })

      changeset =
        order
        |> change(%{
            name: Faker.String.base64(5),
            email: Faker.Internet.safe_email(),
            fulfillment_method: "pickup"
           })
        |> Order.validate()

      assert Keyword.keys(changeset.errors) == [:customer]

      {_, error_info} = changeset.errors[:customer]
      assert error_info[:validation] == :required_for_unlockable
    end
  end

  describe "changeset/4" do
    test "when given opened status" do
      order =
        %Order{ id: Ecto.UUID.generate() }
        |> put_meta(state: :loaded)

      changeset = Order.changeset(order, %{
        email: Faker.Internet.safe_email(),
        name: Faker.String.base64(5),
        fulfillment_method: "pickup",
        status: "opened"
      })

      assert changeset.valid?
      assert changeset.changes[:opened_at]
    end

    test "when given first name and last name" do
      order =
        %Order{ id: Ecto.UUID.generate() }
        |> put_meta(state: :loaded)

      changeset = Order.changeset(order, %{
        email: Faker.Internet.safe_email(),
        first_name: Faker.String.base64(5),
        last_name: Faker.String.base64(5),
        fulfillment_method: "pickup",
        status: "opened"
      })

      assert changeset.valid?
      assert changeset.changes[:opened_at]
      assert changeset.changes[:name]
    end
  end

  describe "balance/1" do
    test "when amounts fields do not equal the same of root line items" do
      account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: account.id
      })
      root1 = Repo.insert!(%OrderLineItem{
        account_id: account.id,
        order_id: order.id,
        name: Faker.String.base64(5),
        charge_quantity: 1,
        sub_total_cents: 300,
        tax_one_cents: 20,
        tax_two_cents: 30,
        tax_three_cents: 50,
        grand_total_cents: 400,
        authorization_total_cents: 400,
        auto_fulfill: false
      })
      Repo.insert!(%OrderLineItem{
        account_id: account.id,
        order_id: order.id,
        parent_id: root1.id,
        name: Faker.String.base64(5),
        charge_quantity: 1,
        sub_total_cents: 400,
        grand_total_cents: 400,
        authorization_total_cents: 400,
        auto_fulfill: false
      })
      root2 = Repo.insert!(%OrderLineItem{
        account_id: account.id,
        order_id: order.id,
        name: Faker.String.base64(5),
        charge_quantity: 1,
        sub_total_cents: 500,
        tax_one_cents: 50,
        tax_two_cents: 40,
        tax_three_cents: 10,
        grand_total_cents: 600,
        authorization_total_cents: 600,
        auto_fulfill: false
      })
      Repo.insert!(%OrderLineItem{
        account_id: account.id,
        order_id: order.id,
        parent_id: root2.id,
        name: Faker.String.base64(5),
        charge_quantity: 1,
        sub_total_cents: 600,
        grand_total_cents: 600,
        authorization_total_cents: 600,
        auto_fulfill: false
      })

      order = Order.balance(order)
      assert order.sub_total_cents == 800
      assert order.tax_one_cents == 70
      assert order.tax_one_cents == 70
      assert order.tax_three_cents == 60
      assert order.grand_total_cents == 1000
      assert order.authorization_total_cents == 1000
    end
  end

  describe "get_payment_status/1" do
    test "when given order has no payment and grand total greater than 0" do
      BalanceDataMock
      |> expect(:list_payment_for_target, fn(_, _) -> [] end)

      result = Order.get_payment_status(%Order{
        grand_total_cents: 100,
        authorization_total_cents: 100
      })

      verify!()
      assert result == "pending"
    end

    test "when given order has no payment and grand total equal to 0" do
      BalanceDataMock
      |> expect(:list_payment_for_target, fn(_, _) -> [] end)

      result = Order.get_payment_status(%Order{ })

      verify!()
      assert result == "paid"
    end

    test "when given order's payment total is equal to order's total" do
      payments = [
        %{ status: "paid", amount_cents: 300, gross_amount_cents: 300 },
        %{ status: "paid", amount_cents: 700, gross_amount_cents: 700 }
      ]
      BalanceDataMock
      |> expect(:list_payment_for_target, fn(_, _) -> payments end)

      result = Order.get_payment_status(%Order{ grand_total_cents: 1000 })

      verify!()
      assert result == "paid"
    end

    test "when given order's payment total is greater than order's total" do
      payments = [
        %{ status: "paid", amount_cents: 400, gross_amount_cents: 400 },
        %{ status: "paid", amount_cents: 700, gross_amount_cents: 700 }
      ]
      BalanceDataMock
      |> expect(:list_payment_for_target, fn(_, _) -> payments end)

      result = Order.get_payment_status(%Order{ grand_total_cents: 1000 })

      verify!()
      assert result == "over_paid"
    end

    test "when given order's payment gross amount is 0" do
      payments = [
        %{ status: "refunded", amount_cents: 200, gross_amount_cents: 0 },
        %{ status: "refunded", amount_cents: 700, gross_amount_cents: 0 }
      ]
      BalanceDataMock
      |> expect(:list_payment_for_target, fn(_, _) -> payments end)

      result = Order.get_payment_status(%Order{ grand_total_cents: 1000 })

      verify!()
      assert result == "refunded"
    end

    test "when given order's payment total is less than order's total" do
      payments = [
        %{ status: "paid", amount_cents: 200, gross_amount_cents: 200 },
        %{ status: "paid", amount_cents: 700, gross_amount_cents: 700 }
      ]
      BalanceDataMock
      |> expect(:list_payment_for_target, fn(_, _) -> payments end)

      result = Order.get_payment_status(%Order{ grand_total_cents: 1000 })

      verify!()
      assert result == "partially_paid"
    end

    test "when given order was never fully paid and some of the order's payment is partially refunded" do
      payments = [
        %{ status: "partially_refunded", amount_cents: 200, gross_amount_cents: 100 },
        %{ status: "paid", amount_cents: 700, gross_amount_cents: 0 }
      ]
      BalanceDataMock
      |> expect(:list_payment_for_target, fn(_, _) -> payments end)

      result = Order.get_payment_status(%Order{ grand_total_cents: 1000 })

      verify!()
      assert result == "partially_paid"
    end

    test "when given order was fully paid but some of the order's payment is partially refunded" do
      payments = [
        %{ status: "partially_refunded", amount_cents: 300, gross_amount_cents: 100 },
        %{ status: "paid", amount_cents: 700, gross_amount_cents: 0 }
      ]
      BalanceDataMock
      |> expect(:list_payment_for_target, fn(_, _) -> payments end)

      result = Order.get_payment_status(%Order{ grand_total_cents: 1000 })

      verify!()
      assert result == "partially_refunded"
    end

    test "when given order was fully paid but some of the order's payment is refunded" do
      payments = [
        %{ status: "refunded", amount_cents: 300, gross_amount_cents: 300 },
        %{ status: "paid", amount_cents: 700, gross_amount_cents: 0 }
      ]
      BalanceDataMock
      |> expect(:list_payment_for_target, fn(_, _) -> payments end)

      result = Order.get_payment_status(%Order{ grand_total_cents: 1000 })

      verify!()
      assert result == "partially_refunded"
    end

    test "when given order's payment authorize total is less than order's authorization amount" do
      payments = [
        %{ status: "authorized", amount_cents: 200, gross_amount_cents: 0 },
        %{ status: "authorized", amount_cents: 700, gross_amount_cents: 0 }
      ]
      BalanceDataMock
      |> expect(:list_payment_for_target, fn(_, _) -> payments end)

      result = Order.get_payment_status(%Order{
        grand_total_cents: 1000,
        authorization_total_cents: 1000
      })

      verify!()
      assert result == "partially_authorized"
    end

    test "when given order's payment authorize total is equal to order's authorization amount" do
      payments = [
        %{ status: "authorized", amount_cents: 300, gross_amount_cents: 0 },
        %{ status: "authorized", amount_cents: 700, gross_amount_cents: 0 }
      ]
      BalanceDataMock
      |> expect(:list_payment_for_target, fn(_, _) -> payments end)

      result = Order.get_payment_status(%Order{
        grand_total_cents: 1000,
        authorization_total_cents: 1000
      })

      verify!()
      assert result == "authorized"
    end
  end

  describe "get_fulfillment_status/1" do
    test "when no line item is fulfilled or returned" do
      account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: account.id
      })
      Repo.insert!(%OrderLineItem{
        account_id: account.id,
        order_id: order.id,
        name: Faker.String.base64(5),
        charge_quantity: 1,
        sub_total_cents: 500,
        grand_total_cents: 500,
        authorization_total_cents: 500,
        auto_fulfill: false
      })

      result = Order.get_fulfillment_status(order)

      assert result == "pending"
    end

    test "when some line item is fulfilled" do
      account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: account.id
      })
      Repo.insert!(%OrderLineItem{
        account_id: account.id,
        order_id: order.id,
        name: Faker.String.base64(5),
        fulfillment_status: "fulfilled",
        charge_quantity: 1,
        sub_total_cents: 500,
        grand_total_cents: 500,
        authorization_total_cents: 500,
        auto_fulfill: false
      })
      Repo.insert!(%OrderLineItem{
        account_id: account.id,
        order_id: order.id,
        name: Faker.String.base64(5),
        charge_quantity: 1,
        sub_total_cents: 500,
        grand_total_cents: 500,
        authorization_total_cents: 500,
        auto_fulfill: false
      })

      result = Order.get_fulfillment_status(order)

      assert result == "partially_fulfilled"
    end

    test "when all line item is fulfilled" do
      account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: account.id
      })
      Repo.insert!(%OrderLineItem{
        account_id: account.id,
        order_id: order.id,
        name: Faker.String.base64(5),
        fulfillment_status: "fulfilled",
        charge_quantity: 1,
        sub_total_cents: 500,
        grand_total_cents: 500,
        authorization_total_cents: 500,
        auto_fulfill: false
      })
      Repo.insert!(%OrderLineItem{
        account_id: account.id,
        order_id: order.id,
        name: Faker.String.base64(5),
        fulfillment_status: "fulfilled",
        charge_quantity: 1,
        sub_total_cents: 500,
        grand_total_cents: 500,
        authorization_total_cents: 500,
        auto_fulfill: false
      })

      result = Order.get_fulfillment_status(order)

      assert result == "fulfilled"
    end

    test "when some line item is returned" do
      account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: account.id
      })
      Repo.insert!(%OrderLineItem{
        account_id: account.id,
        order_id: order.id,
        name: Faker.String.base64(5),
        fulfillment_status: "returned",
        charge_quantity: 1,
        sub_total_cents: 500,
        grand_total_cents: 500,
        authorization_total_cents: 500,
        auto_fulfill: false
      })
      Repo.insert!(%OrderLineItem{
        account_id: account.id,
        order_id: order.id,
        name: Faker.String.base64(5),
        charge_quantity: 1,
        sub_total_cents: 500,
        grand_total_cents: 500,
        authorization_total_cents: 500,
        auto_fulfill: false
      })

      result = Order.get_fulfillment_status(order)

      assert result == "partially_returned"
    end

    test "when all line item is returned" do
      account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: account.id
      })
      Repo.insert!(%OrderLineItem{
        account_id: account.id,
        order_id: order.id,
        name: Faker.String.base64(5),
        fulfillment_status: "returned",
        charge_quantity: 1,
        sub_total_cents: 500,
        grand_total_cents: 500,
        authorization_total_cents: 500,
        auto_fulfill: false
      })
      Repo.insert!(%OrderLineItem{
        account_id: account.id,
        order_id: order.id,
        name: Faker.String.base64(5),
        fulfillment_status: "returned",
        charge_quantity: 1,
        sub_total_cents: 500,
        grand_total_cents: 500,
        authorization_total_cents: 500,
        auto_fulfill: false
      })

      result = Order.get_fulfillment_status(order)

      assert result == "returned"
    end
  end

  describe "process/2" do
    test "when given order has auto fulfillabe line item" do
      account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: account.id
      })
      Repo.insert!(%OrderLineItem{
        account_id: account.id,
        order_id: order.id,
        name: Faker.String.base64(5),
        charge_quantity: 1,
        sub_total_cents: 500,
        grand_total_cents: 500,
        authorization_total_cents: 500,
        auto_fulfill: true
      })
      Repo.insert!(%OrderLineItem{
        account_id: account.id,
        order_id: order.id,
        name: Faker.String.base64(5),
        charge_quantity: 1,
        sub_total_cents: 500,
        grand_total_cents: 500,
        authorization_total_cents: 500,
        auto_fulfill: false
      })
      changeset = change(%Order{}, %{ status: "opened" })

      fulfillment = %Fulfillment{ id: Ecto.UUID.generate() }
      fli = %FulfillmentLineItem{ id: Ecto.UUID.generate(), fulfillment_id: fulfillment.id }
      DistributionDataMock
      |> expect(:create_fulfillment, fn(_) -> fulfillment end)
      |> expect(:create_fulfillment_line_item, fn(_) -> fli end)

      Order.process(order, changeset)

      verify!()
    end
  end
end
