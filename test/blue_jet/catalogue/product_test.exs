defmodule BlueJet.Catalogue.ProductTest do
  use BlueJet.DataCase

  alias BlueJet.Identity.Account
  alias BlueJet.Goods.Stockable
  alias BlueJet.Catalogue.Product

  describe "schema" do
    test "when account is deleted product is automatically deleted" do
      account = Repo.insert!(%Account{})
      product = Repo.insert!(%Product{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      Repo.delete!(account)

      refute Repo.get(Product, product.id)
    end

    test "defaults" do
      product = %Product{}

      assert product.status == "draft"
      assert product.kind == "simple"
      assert product.name_sync == "disabled"
      assert product.sort_index == 0
      assert product.maximum_public_order_quantity == 999
      assert product.primary == false
      assert product.auto_fulfill == false
      assert product.custom_data == %{}
      assert product.translations == %{}
    end
  end

  test "writable_fields/0" do
    assert Product.writable_fields() == [
      :status,
      :code,
      :kind,
      :name_sync,
      :name,
      :short_name,
      :print_name,
      :sort_index,
      :source_quantity,
      :maximum_public_order_quantity,
      :primary,
      :auto_fulfill,
      :caption,
      :description,
      :custom_data,
      :source_id,
      :source_type,
      :avatar_id,
      :parent_id
    ]
  end

  describe "validate/1" do
    #
    # MARK: Product simple
    #
    test "when missing required fields" do
      changeset =
        change(%Product{}, %{})
        |> Product.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:name, :source_id, :source_type]
    end

    test "when given invalid source" do
      account = Repo.insert!(%Account{})
      changeset =
        change(%Product{ account_id: account.id }, %{
          source_id: Ecto.UUID.generate(),
          source_type: "Stockable",
          name: Faker.String.base64(5)
        })
        |> Product.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:source_id]
    end

    test "when given valid source" do
      account = Repo.insert!(%Account{})
      stockable = Repo.insert!(%Stockable{
        account_id: account.id,
        name: Faker.String.base64(5),
        unit_of_measure: Faker.String.base64(2)
      })
      changeset =
        change(%Product{ account_id: account.id }, %{
          source_id: stockable.id,
          source_type: "Stockable",
          name: Faker.String.base64(5)
        })
        |> Product.validate()

      assert changeset.valid?
    end

    #
    # MARK: Product with variants
    #
    test "when given product with variants and missing required fields" do
      changeset =
        change(%Product{}, %{ kind: "with_variants" })
        |> Product.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:name]
    end

    test "when given product with variants with invalid status" do
      changeset =
        change(%Product{}, %{
          kind: "with_variants",
          name: Faker.String.base64(5),
          status: "internal"
        })
        |> Product.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:status]

      {_, error_info} = changeset.errors[:status]
      assert error_info[:validation] == "require_internal_variant"
    end

    test "when given product combo and missing required fields" do
      changeset =
        change(%Product{}, %{ kind: "combo" })
        |> Product.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:name]
    end

    test "when given product variant and missing required fields" do
      changeset =
        change(%Product{}, %{ kind: "variant" })
        |> Product.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:name, :parent_id, :source_id, :source_type]
    end

    test "when given product item and missing required fields" do
      changeset =
        change(%Product{}, %{ kind: "item" })
        |> Product.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:name, :parent_id, :source_id, :source_type]
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
