defmodule BlueJet.Fulfillment.FulfillmentItemTest do
  use BlueJet.DataCase

  alias BlueJet.Identity.Account
  alias BlueJet.Storefront.{Order, OrderLineItem}
  alias BlueJet.Fulfillment.{FulfillmentPackage, FulfillmentItem}

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
    end
  end
end
