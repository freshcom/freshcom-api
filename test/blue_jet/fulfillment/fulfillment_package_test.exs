defmodule BlueJet.Fulfillment.FulfillmentPackageTest do
  use BlueJet.DataCase

  alias BlueJet.Identity.Account
  alias BlueJet.Fulfillment.FulfillmentPackage

  test "writable_fields/0" do
    assert FulfillmentPackage.writable_fields() == [
      :status,
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

  describe "validate/1" do
    test "when missing required fields" do
      changeset =
        change(%FulfillmentPackage{}, %{})
        |> FulfillmentPackage.validate()

      assert changeset.valid? == false
      assert Keyword.keys(changeset.errors) == [:order_id]
    end
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
end
