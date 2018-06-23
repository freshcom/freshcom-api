defmodule BlueJet.Fulfillment.FulfillmentItemTest do
  use BlueJet.DataCase

  import Mox

  alias BlueJet.Identity.Account
  alias BlueJet.Goods.{Unlockable, Depositable}
  alias BlueJet.Crm.{Customer, PointAccount, PointTransaction}
  alias BlueJet.Storefront.{Order, OrderLineItem}
  alias BlueJet.Fulfillment.{GoodsServiceMock, CrmServiceMock}
  alias BlueJet.Fulfillment.{FulfillmentPackage, FulfillmentItem, ReturnPackage, ReturnItem, Unlock}

  test "writable_fields/0" do
    assert FulfillmentItem.writable_fields() == [
      :status,
      :code,
      :name,
      :label,
      :quantity,
      :print_name,
      :caption,
      :description,
      :custom_data,
      :translations,
      :order_line_item_id,
      :target_id,
      :target_type,
      :source_id,
      :source_type,
      :package_id
    ]
  end

  describe "validate/1" do
    test "when missing required fields" do
      changeset =
        change(%FulfillmentItem{})
        |> Map.put(:action, :insert)
        |> FulfillmentItem.validate()

      assert changeset.valid? == false
      assert Keyword.keys(changeset.errors) == [:quantity, :order_line_item_id, :package_id]
    end
  end

  describe "changeset/3" do
    test "action should be marked as insert" do
      changeset = FulfillmentItem.changeset(%FulfillmentItem{}, :insert, %{})

      assert changeset.action == :insert
      assert changeset.valid? == false
    end

    test "order_id should be change to the same as package" do
      account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: account.id
      })
      order_line_item = Repo.insert!(%OrderLineItem{
        account_id: account.id,
        order_id: order.id,
        name: Faker.Commerce.product_name(),
        charge_quantity: 1,
        sub_total_cents: 500,
        grand_total_cents: 500,
        authorization_total_cents: 500,
        auto_fulfill: true
      })
      package = Repo.insert!(%FulfillmentPackage{
        account_id: account.id,
        order_id: order.id
      })

      changeset =
        %FulfillmentItem{ account_id: account.id, account: account }
        |> FulfillmentItem.changeset(:insert, %{
            package_id: package.id,
            order_line_item_id: order_line_item.id,
            quantity: 1
           })

      assert changeset.valid?
      assert changeset.changes[:order_id] == order.id
    end
  end

  describe "changeset/5" do
    test "action should be marked as update" do
      account = %Account{}
      changeset = FulfillmentItem.changeset(%FulfillmentItem{ account: account }, :update, %{})

      assert changeset.action == :update
      assert changeset.valid?
    end
  end

  describe "get_status/1" do
    test "when there is no return item" do
      fulfillment_item1 = %FulfillmentItem{ status: "pending" }
      fulfillment_item2 = %FulfillmentItem{ status: "fulfilled" }
      fulfillment_item3 = %FulfillmentItem{ status: "discarded" }

      assert FulfillmentItem.get_status(fulfillment_item1) == "pending"
      assert FulfillmentItem.get_status(fulfillment_item2) == "fulfilled"
      assert FulfillmentItem.get_status(fulfillment_item3) == "discarded"
    end

    test "when returned quantity is smaller than fulfilled quantity" do
      account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: account.id
      })
      order_line_item = Repo.insert!(%OrderLineItem{
        account_id: account.id,
        order_id: order.id,
        name: Faker.Commerce.product_name(),
        charge_quantity: 1,
        sub_total_cents: 500,
        grand_total_cents: 500,
        authorization_total_cents: 500,
        auto_fulfill: true
      })
      fulfillment_package = Repo.insert!(%FulfillmentPackage{
        account_id: account.id,
        order_id: order.id
      })
      return_package = Repo.insert!(%ReturnPackage{
        account_id: account.id,
        order_id: order.id
      })

      fulfillment_item = Repo.insert!(%FulfillmentItem{
        account_id: account.id,
        order_id: order.id,
        package_id: fulfillment_package.id,
        order_line_item_id: order_line_item.id,
        status: "fulfilled",
        quantity: 5
      })
      Repo.insert!(%ReturnItem{
        account_id: account.id,
        order_id: order.id,
        package_id: return_package.id,
        order_line_item_id: order_line_item.id,
        fulfillment_item_id: fulfillment_item.id,
        status: "returned",
        quantity: 3
      })
      Repo.insert!(%ReturnItem{
        account_id: account.id,
        order_id: order.id,
        package_id: return_package.id,
        order_line_item_id: order_line_item.id,
        fulfillment_item_id: fulfillment_item.id,
        status: "pending",
        quantity: 2
      })

      assert FulfillmentItem.get_status(fulfillment_item) == "partially_returned"
    end

    test "when returned quantity is same as fulfilled quantity" do
      account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: account.id
      })
      order_line_item = Repo.insert!(%OrderLineItem{
        account_id: account.id,
        order_id: order.id,
        name: Faker.Commerce.product_name(),
        charge_quantity: 1,
        sub_total_cents: 500,
        grand_total_cents: 500,
        authorization_total_cents: 500,
        auto_fulfill: true
      })
      fulfillment_package = Repo.insert!(%FulfillmentPackage{
        account_id: account.id,
        order_id: order.id
      })
      return_package = Repo.insert!(%ReturnPackage{
        account_id: account.id,
        order_id: order.id
      })

      fulfillment_item = Repo.insert!(%FulfillmentItem{
        account_id: account.id,
        order_id: order.id,
        package_id: fulfillment_package.id,
        order_line_item_id: order_line_item.id,
        status: "fulfilled",
        quantity: 5
      })
      Repo.insert!(%ReturnItem{
        account_id: account.id,
        order_id: order.id,
        package_id: return_package.id,
        order_line_item_id: order_line_item.id,
        fulfillment_item_id: fulfillment_item.id,
        status: "returned",
        quantity: 3
      })
      Repo.insert!(%ReturnItem{
        account_id: account.id,
        order_id: order.id,
        package_id: return_package.id,
        order_line_item_id: order_line_item.id,
        fulfillment_item_id: fulfillment_item.id,
        status: "returned",
        quantity: 2
      })

      assert FulfillmentItem.get_status(fulfillment_item) == "returned"
    end
  end

  describe "fulfill/1" do
    test "when fulfilling unlockable" do
      account = Repo.insert!(%Account{})
      unlockable = Repo.insert!(%Unlockable{
        account_id: account.id,
        name: Faker.Commerce.product_name()
      })
      customer = Repo.insert!(%Customer{
        account_id: account.id,
        name: Faker.Name.name()
      })

      fulfillment_item = %FulfillmentItem{
        account: account,
        package: %{ customer_id: customer.id }
      }
      changes = %{
        status: "fulfilled",
        target_type: "Unlockable",
        target_id: unlockable.id
      }

      {:ok, changeset} =
        change(fulfillment_item, changes)
        |> FulfillmentItem.fulfill()

      unlock = Repo.get_by(Unlock, customer_id: customer.id, unlockable_id: unlockable.id)
      assert unlock
      assert changeset.changes[:source_type] == "Unlock"
      assert changeset.changes[:source_id] == unlock.id
    end

    test "when fulfilling unlockable that is already unlocked" do
      account = Repo.insert!(%Account{})
      unlockable = Repo.insert!(%Unlockable{
        account_id: account.id,
        name: Faker.Commerce.product_name()
      })
      customer = Repo.insert!(%Customer{
        account_id: account.id,
        name: Faker.Name.name()
      })
      Repo.insert!(%Unlock{
        account_id: account.id,
        customer_id: customer.id,
        unlockable_id: unlockable.id
      })

      fulfillment_item = %FulfillmentItem{
        account: account,
        package: %{ customer_id: customer.id }
      }
      changes = %{
        status: "fulfilled",
        target_type: "Unlockable",
        target_id: unlockable.id
      }

      {:error, _} =
        change(fulfillment_item, changes)
        |> FulfillmentItem.fulfill()
    end

    test "when fulfilling depositable" do
      account = %Account{}

      depositable = %Depositable{
        id: Ecto.UUID.generate(),
        amount: 500,
        gateway: "freshcom"
      }
      GoodsServiceMock
      |> expect(:get_depositable, fn(fields, _) ->
          assert fields[:id] == depositable.id
          depositable
         end)

      customer = %Customer{
        id: Ecto.UUID.generate()
      }
      point_account = %PointAccount{}
      point_transaction = %PointTransaction{
        id: Ecto.UUID.generate()
      }

      CrmServiceMock
      |> expect(:get_point_account, fn(fields, _) ->
          assert fields[:customer_id] == customer.id
          point_account
         end)
      |> expect(:create_point_transaction, fn(_, _) ->
          {:ok, point_transaction}
         end)

      fulfillment_item = %FulfillmentItem{
        account: account,
        package: %{ customer_id: customer.id },
        quantity: 2
      }
      changes = %{
        status: "fulfilled",
        target_type: "Depositable",
        target_id: depositable.id
      }

      {:ok, changeset} =
        change(fulfillment_item, changes)
        |> FulfillmentItem.fulfill()

      verify!()
      assert changeset.changes[:source_type] == "PointTransaction"
      assert changeset.changes[:source_id] == point_transaction.id
    end

    test "when fulfilling point transaction" do
      account = %Account{}

      point_transaction = %PointTransaction{
        id: Ecto.UUID.generate()
      }
      CrmServiceMock
      |> expect(:update_point_transaction, fn(id, _, _) ->
          assert id == point_transaction.id
          {:ok, point_transaction}
         end)

      fulfillment_item = %FulfillmentItem{
        account: account
      }
      changes = %{
        status: "fulfilled",
        target_type: "PointTransaction",
        target_id: point_transaction.id
      }

      {:ok, changeset} =
        change(fulfillment_item, changes)
        |> FulfillmentItem.fulfill()

      verify!()
      assert changeset.changes[:source_type] == "PointTransaction"
      assert changeset.changes[:source_id] == point_transaction.id
    end
  end
end
