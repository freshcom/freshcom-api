defmodule BlueJet.OrderTest do
  use BlueJet.DataCase

  alias Ecto.Changeset
  alias BlueJet.Storefront.Order

  describe "schema" do
    test "defaults" do
      struct = %Order{}

      assert struct.status == "cart"
      assert struct.payment_status == "pending"
      assert struct.fulfillment_status == "pending"

      assert struct.sub_total_cents == 0
      assert struct.tax_one_cents == 0
      assert struct.tax_two_cents == 0
      assert struct.tax_three_cents == 0
      assert struct.grand_total_cents == 0
      assert struct.custom_data == %{}
      assert struct.translations == %{}
    end
  end

  describe "required_fields/2" do
    test "on new order" do
      changeset = Changeset.change(%Order{})
      required_fields = Order.required_fields(changeset)

      assert required_fields == [
        :account_id,
        :status,
        :fulfillment_status,
        :payment_status
      ]
    end

    test "on existing order" do
      order = Ecto.put_meta(%Order{}, state: :loaded)
      changeset = Changeset.change(order)
      required_fields = Order.required_fields(changeset)

      assert required_fields == [
        :account_id,
        :status,
        :fulfillment_status,
        :payment_status,
        :email,
        :fulfillment_method,
        :first_name,
        :last_name
      ]
    end

    test "on existing order with name" do
      order = Ecto.put_meta(%Order{}, state: :loaded)
      changeset = Changeset.change(order, %{ name: "Roy" })
      required_fields = Order.required_fields(changeset)

      assert required_fields == [
        :account_id,
        :status,
        :fulfillment_status,
        :payment_status,
        :email,
        :fulfillment_method
      ]
    end

    test "on existing order with first name" do
      order = Ecto.put_meta(%Order{}, state: :loaded)
      changeset = Changeset.change(order, %{ first_name: "Roy" })
      required_fields = Order.required_fields(changeset)

      assert required_fields == [
        :account_id,
        :status,
        :fulfillment_status,
        :payment_status,
        :email,
        :fulfillment_method,
        :last_name
      ]
    end

    test "on existing order with last name" do
      order = Ecto.put_meta(%Order{}, state: :loaded)
      changeset = Changeset.change(order, %{ last_name: "Roy" })
      required_fields = Order.required_fields(changeset)

      assert required_fields == [
        :account_id,
        :status,
        :fulfillment_status,
        :payment_status,
        :email,
        :fulfillment_method,
        :first_name
      ]
    end
  end
end
