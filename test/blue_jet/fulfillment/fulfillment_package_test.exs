defmodule BlueJet.Fulfillment.FulfillmentPackageTest do
  use BlueJet.DataCase

  alias BlueJet.Identity.Account
  alias BlueJet.Storefront.{Order, OrderLineItem}
  alias BlueJet.Fulfillment.{FulfillmentPackage, FulfillmentItem}

  test "writable_fields/0" do
    assert FulfillmentPackage.writable_fields() == [
      :code,
      :name,
      :label,
      :caption,
      :description,
      :custom_data,
      :translations,
      :order_id,
      :customer_id
    ]
  end

  describe "changeset/3" do
    test "action should be marked as insert" do
      changeset = FulfillmentPackage.changeset(%FulfillmentPackage{}, :insert, %{})

      assert changeset.action == :insert
    end
  end

  describe "changeset/5" do
    test "action should be marked as update" do
      account = %Account{}
      changeset = FulfillmentPackage.changeset(%FulfillmentPackage{ account: account }, :update, %{})

      assert changeset.action == :update
    end
  end

  describe "get_status/1" do
    test "when no item for package" do
      fulfillment_package = %FulfillmentPackage{}
      assert FulfillmentPackage.get_status(fulfillment_package) == "pending"
    end

    test "when all item is pending" do
      account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: account.id
      })
      oli1 = Repo.insert!(%OrderLineItem{
        account_id: account.id,
        order_id: order.id,
        name: Faker.Name.name(),
        charge_quantity: 5,
        sub_total_cents: 500,
        grand_total_cents: 500,
        authorization_total_cents: 500,
        auto_fulfill: true
      })
      fulfillment_package = Repo.insert!(%FulfillmentPackage{
        account_id: account.id,
        order_id: order.id
      })
      Repo.insert!(%FulfillmentItem{
        account_id: account.id,
        order_id: order.id,
        order_line_item_id: oli1.id,
        package_id: fulfillment_package.id,
        quantity: 1,
        status: "discarded"
      })
      Repo.insert!(%FulfillmentItem{
        account_id: account.id,
        order_id: order.id,
        order_line_item_id: oli1.id,
        package_id: fulfillment_package.id,
        quantity: 3,
        status: "pending"
      })

      assert FulfillmentPackage.get_status(fulfillment_package) == "pending"
    end

    test "when some items are pending and some items are fulfilled" do
      account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: account.id
      })
      oli1 = Repo.insert!(%OrderLineItem{
        account_id: account.id,
        order_id: order.id,
        name: Faker.Name.name(),
        charge_quantity: 5,
        sub_total_cents: 500,
        grand_total_cents: 500,
        authorization_total_cents: 500,
        auto_fulfill: true
      })
      fulfillment_package = Repo.insert!(%FulfillmentPackage{
        account_id: account.id,
        order_id: order.id
      })
      Repo.insert!(%FulfillmentItem{
        account_id: account.id,
        order_id: order.id,
        order_line_item_id: oli1.id,
        package_id: fulfillment_package.id,
        quantity: 1,
        status: "discarded"
      })
      Repo.insert!(%FulfillmentItem{
        account_id: account.id,
        order_id: order.id,
        order_line_item_id: oli1.id,
        package_id: fulfillment_package.id,
        quantity: 2,
        status: "pending"
      })
      Repo.insert!(%FulfillmentItem{
        account_id: account.id,
        order_id: order.id,
        order_line_item_id: oli1.id,
        package_id: fulfillment_package.id,
        quantity: 3,
        status: "fulfilled"
      })

      assert FulfillmentPackage.get_status(fulfillment_package) == "partially_fulfilled"
    end

    test "when all item is fulfilled" do
      account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: account.id
      })
      oli1 = Repo.insert!(%OrderLineItem{
        account_id: account.id,
        order_id: order.id,
        name: Faker.Name.name(),
        charge_quantity: 5,
        sub_total_cents: 500,
        grand_total_cents: 500,
        authorization_total_cents: 500,
        auto_fulfill: true
      })
      fulfillment_package = Repo.insert!(%FulfillmentPackage{
        account_id: account.id,
        order_id: order.id
      })
      Repo.insert!(%FulfillmentItem{
        account_id: account.id,
        order_id: order.id,
        order_line_item_id: oli1.id,
        package_id: fulfillment_package.id,
        quantity: 1,
        status: "discarded"
      })
      Repo.insert!(%FulfillmentItem{
        account_id: account.id,
        order_id: order.id,
        order_line_item_id: oli1.id,
        package_id: fulfillment_package.id,
        quantity: 2,
        status: "fulfilled"
      })
      Repo.insert!(%FulfillmentItem{
        account_id: account.id,
        order_id: order.id,
        order_line_item_id: oli1.id,
        package_id: fulfillment_package.id,
        quantity: 3,
        status: "fulfilled"
      })

      assert FulfillmentPackage.get_status(fulfillment_package) == "fulfilled"
    end

    test "when some item is returned" do
      account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: account.id
      })
      oli1 = Repo.insert!(%OrderLineItem{
        account_id: account.id,
        order_id: order.id,
        name: Faker.Name.name(),
        charge_quantity: 5,
        sub_total_cents: 500,
        grand_total_cents: 500,
        authorization_total_cents: 500,
        auto_fulfill: true
      })
      fulfillment_package = Repo.insert!(%FulfillmentPackage{
        account_id: account.id,
        order_id: order.id
      })
      Repo.insert!(%FulfillmentItem{
        account_id: account.id,
        order_id: order.id,
        order_line_item_id: oli1.id,
        package_id: fulfillment_package.id,
        quantity: 1,
        status: "discarded"
      })
      Repo.insert!(%FulfillmentItem{
        account_id: account.id,
        order_id: order.id,
        order_line_item_id: oli1.id,
        package_id: fulfillment_package.id,
        quantity: 2,
        status: "fulfilled"
      })
      Repo.insert!(%FulfillmentItem{
        account_id: account.id,
        order_id: order.id,
        order_line_item_id: oli1.id,
        package_id: fulfillment_package.id,
        quantity: 3,
        status: "returned"
      })

      assert FulfillmentPackage.get_status(fulfillment_package) == "partially_returned"
    end

    test "when all item is discarded" do
      account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: account.id
      })
      oli1 = Repo.insert!(%OrderLineItem{
        account_id: account.id,
        order_id: order.id,
        name: Faker.Name.name(),
        charge_quantity: 5,
        sub_total_cents: 500,
        grand_total_cents: 500,
        authorization_total_cents: 500,
        auto_fulfill: true
      })
      fulfillment_package = Repo.insert!(%FulfillmentPackage{
        account_id: account.id,
        order_id: order.id
      })
      Repo.insert!(%FulfillmentItem{
        account_id: account.id,
        order_id: order.id,
        order_line_item_id: oli1.id,
        package_id: fulfillment_package.id,
        quantity: 1,
        status: "discarded"
      })

      assert FulfillmentPackage.get_status(fulfillment_package) == "discarded"
    end

    test "when all item is returned" do
      account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: account.id
      })
      oli1 = Repo.insert!(%OrderLineItem{
        account_id: account.id,
        order_id: order.id,
        name: Faker.Name.name(),
        charge_quantity: 5,
        sub_total_cents: 500,
        grand_total_cents: 500,
        authorization_total_cents: 500,
        auto_fulfill: true
      })
      fulfillment_package = Repo.insert!(%FulfillmentPackage{
        account_id: account.id,
        order_id: order.id
      })
      Repo.insert!(%FulfillmentItem{
        account_id: account.id,
        order_id: order.id,
        order_line_item_id: oli1.id,
        package_id: fulfillment_package.id,
        quantity: 1,
        status: "discarded"
      })
      Repo.insert!(%FulfillmentItem{
        account_id: account.id,
        order_id: order.id,
        order_line_item_id: oli1.id,
        package_id: fulfillment_package.id,
        quantity: 3,
        status: "returned"
      })

      assert FulfillmentPackage.get_status(fulfillment_package) == "returned"
    end
  end
end
