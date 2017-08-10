defmodule BlueJet.OrderTest do
  use BlueJet.DataCase, async: true

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
      assert struct.custom_data == %{}
      assert struct.translations == %{}
      assert struct.sub_total_cents == 0
      assert struct.grand_total_cents == 0
      assert struct.payment_status == "pending"
    end
  end

  describe "required_fields/1" do
    test "status=cart" do
      required_fields = Order.required_fields(%{ status: "cart" })
      assert required_fields == [:account_id, :status]
    end

    test "status=opened, fulfillment_method=pickup, payment_status=pending and payment_gateway=custom" do
      required_fields = Order.required_fields(%{ status: "opened", fulfillment_method: "pickup", payment_status: "pending", payment_gateway: "custom" })
      assert required_fields == [:account_id, :status, :email, :first_name, :last_name]
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
