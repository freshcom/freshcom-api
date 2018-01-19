defmodule BlueJet.OrderTest do
  use BlueJet.DataCase

  alias Ecto.Changeset
  alias BlueJet.Identity.Account
  alias BlueJet.Storefront.Order
  alias BlueJet.Storefront.OrderLineItem
  alias BlueJet.CRM.Customer

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
      assert Keyword.keys(changeset.errors) == [:email, :fulfillment_method, :first_name, :last_name]
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

  # describe "required_fields/2" do
  #   test "on new order" do
  #     changeset = Changeset.change(%Order{})
  #     required_fields = Order.required_fields(changeset)

  #     assert required_fields == [
  #       :account_id,
  #       :status,
  #       :fulfillment_status,
  #       :payment_status
  #     ]
  #   end

  #   test "on existing order" do
  #     order = Ecto.put_meta(%Order{}, state: :loaded)
  #     changeset = Changeset.change(order)
  #     required_fields = Order.required_fields(changeset)

  #     assert required_fields == [
  #       :account_id,
  #       :status,
  #       :fulfillment_status,
  #       :payment_status,
  #       :email,
  #       :fulfillment_method,
  #       :first_name,
  #       :last_name
  #     ]
  #   end

  #   test "on existing order with name" do
  #     order = Ecto.put_meta(%Order{}, state: :loaded)
  #     changeset = Changeset.change(order, %{ name: "Roy" })
  #     required_fields = Order.required_fields(changeset)

  #     assert required_fields == [
  #       :account_id,
  #       :status,
  #       :fulfillment_status,
  #       :payment_status,
  #       :email,
  #       :fulfillment_method
  #     ]
  #   end

  #   test "on existing order with first name" do
  #     order = Ecto.put_meta(%Order{}, state: :loaded)
  #     changeset = Changeset.change(order, %{ first_name: "Roy" })
  #     required_fields = Order.required_fields(changeset)

  #     assert required_fields == [
  #       :account_id,
  #       :status,
  #       :fulfillment_status,
  #       :payment_status,
  #       :email,
  #       :fulfillment_method,
  #       :last_name
  #     ]
  #   end

  #   test "on existing order with last name" do
  #     order = Ecto.put_meta(%Order{}, state: :loaded)
  #     changeset = Changeset.change(order, %{ last_name: "Roy" })
  #     required_fields = Order.required_fields(changeset)

  #     assert required_fields == [
  #       :account_id,
  #       :status,
  #       :fulfillment_status,
  #       :payment_status,
  #       :email,
  #       :fulfillment_method,
  #       :first_name
  #     ]
  #   end
  # end
end
