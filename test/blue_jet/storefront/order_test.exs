defmodule BlueJet.OrderTest do
  use BlueJet.DataCase

  alias Ecto.Changeset
  alias BlueJet.Storefront.Order

  # @valid_params %{
  #   account_id: Ecto.UUID.generate(),
  #   status: "active",
  #   name: "Apple",
  #   item_mode: "all",
  #   custom_data: %{
  #     kind: "Gala"
  #   }
  # }
  # @invalid_params %{}

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

  # describe "changeset/1" do
  #   test "with struct in :built state, valid params, en locale" do
  #     changeset = Product.changeset(%Product{}, @valid_params)

  #     assert changeset.valid?
  #     assert changeset.changes.account_id
  #     assert changeset.changes.status
  #     assert changeset.changes.name
  #     assert changeset.changes.item_mode
  #   end

  #   test "with struct in :built state, valid params, zh-CN locale" do
  #     changeset = Product.changeset(%Product{}, @valid_params, "zh-CN")

  #     assert changeset.valid?
  #     assert changeset.changes.account_id
  #     assert changeset.changes.status
  #     assert changeset.changes.item_mode
  #     assert changeset.changes.translations["zh-CN"]
  #     refute Map.get(changeset.changes, :name)
  #     refute Map.get(changeset.changes, :custom_data)
  #   end

  #   test "with struct in :loaded state, valid params" do
  #     struct = Ecto.put_meta(%Product{ account_id: Ecto.UUID.generate() }, state: :loaded)
  #     changeset = Product.changeset(struct, @valid_params)

  #     assert changeset.valid?
  #     assert changeset.changes.status
  #     assert changeset.changes.name
  #     assert changeset.changes.item_mode
  #     assert changeset.changes.custom_data
  #     refute Map.get(changeset.changes, :account_id)
  #   end

  #   test "with struct in :built state, invalid params" do
  #     changeset = Product.changeset(%Product{}, @invalid_params)

  #     refute changeset.valid?
  #   end
  # end
end
