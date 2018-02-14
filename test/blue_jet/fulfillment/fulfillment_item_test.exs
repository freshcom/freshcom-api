defmodule BlueJet.Fulfillment.FulfillmentItemTest do
  use BlueJet.DataCase

  alias BlueJet.Identity.Account
  alias BlueJet.Fulfillment.FulfillmentItem

  test "writable_fields/0" do
    assert FulfillmentItem.writable_fields() == [
      :status,
      :code,
      :name,
      :label,
      :caption,
      :description,
      :custom_data,
      :translations,
      :order_id,
      :customer_id,
      :package_id
    ]
  end

  describe "validate/1" do
    test "when missing required fields" do
      changeset =
        change(%FulfillmentItem{}, %{})
        |> FulfillmentItem.validate()

      assert changeset.valid? == false
      assert Keyword.keys(changeset.errors) == [:order_id]
    end
  end

  describe "changeset/3" do
    test "action should be marked as insert" do
      changeset = FulfillmentItem.changeset(%FulfillmentItem{}, :insert, %{})

      assert changeset.action == :insert
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
