defmodule BlueJet.Catalogue.ProductTest do
  use BlueJet.DataCase

  import BlueJet.Catalogue.TestHelper
  import BlueJet.Goods.TestHelper

  alias BlueJet.Identity.Account
  alias BlueJet.Catalogue.Product

  describe "schema" do
    test "when account is deleted product is automatically deleted" do
      account = account_fixture()
      product = product_fixture(account)

      Repo.delete!(account)

      refute Repo.get(Product, product.id)
    end

    test "when parent is deleted variant should be automatically deleted" do
      account = account_fixture()
      parent = product_fixture(account, %{kind: "with_variants"})
      variant = product_fixture(account, %{kind: "variant", parent_id: parent.id})

      Repo.delete!(parent)
      refute Repo.get(Product, variant.id)
    end

    test "when parent is deleted item should be automatically deleted" do
      account = account_fixture()
      parent = product_fixture(account, %{kind: "combo"})
      item = product_fixture(account, %{kind: "item", parent_id: parent.id})

      Repo.delete!(parent)
      refute Repo.get(Product, item.id)
    end

    test "defaults" do
      product = %Product{}

      assert product.status == "draft"
      assert product.kind == "simple"
      assert product.name_sync == "disabled"
      assert product.sort_index == 1000
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
      :label,
      :name_sync,
      :name,
      :short_name,
      :print_name,
      :sort_index,
      :goods_quantity,
      :maximum_public_order_quantity,
      :price_proportion_index,
      :primary,
      :auto_fulfill,
      :caption,
      :description,
      :custom_data,
      :translations,
      :goods_id,
      :goods_type,
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
        %Product{}
        |> change(%{})
        |> Map.put(:action, :insert)
        |> Product.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:name, :goods_id, :goods_type]
    end

    test "when given invalid goods" do
      account = %Account{id: UUID.generate()}

      changeset =
        change(%Product{}, %{
          account: account,
          goods_id: UUID.generate(),
          goods_type: "Stockable",
          name: Faker.String.base64(5)
        })
        |> Map.put(:action, :insert)
        |> Product.validate()

      assert changeset.valid? == false
      assert Keyword.keys(changeset.errors) == [:goods]
    end

    test "when given valid goods" do
      account = account_fixture()
      stockable = stockable_fixture(account)
      product = %Product{account_id: account.id, account: account}

      changeset =
        product
        |> change(goods_id: stockable.id, goods_type: "Stockable", name: Faker.Commerce.product_name())
        |> Map.put(:action, :insert)
        |> Product.validate()

      assert changeset.valid?
    end

    #
    # MARK: Product with variants
    #
    test "when given product with variants and missing required fields" do
      changeset =
        %Product{}
        |> change(kind: "with_variants")
        |> Map.put(:action, :insert)
        |> Product.validate()

      assert changeset.valid? == false
      assert Keyword.keys(changeset.errors) == [:name]
    end

    test "when given product with variants with invalid internal status due to missing internal variant" do
      changeset =
        %Product{}
        |> change(kind: "with_variants", status: "internal", name: Faker.Commerce.product_name())
        |> Map.put(:action, :insert)
        |> Product.validate()

      assert changeset.valid? == false
      assert Keyword.keys(changeset.errors) == [:status]

      {_, error_info} = changeset.errors[:status]
      assert error_info[:code] == "cannot_be_internal"
    end

    test "when given product with variants with valid internal status" do
      account = account_fixture()
      product = product_fixture(account, %{kind: "with_variants"})
      product_fixture(account, %{kind: "variant", status: "internal", parent_id: product.id})

      changeset =
        product
        |> change(status: "internal")
        |> Map.put(:action, :update)
        |> Product.validate()

      assert changeset.valid?
    end

    test "when given product with variants with invalid active status due to missing active variant" do
      changeset =
        %Product{}
        |> change(kind: "with_variants", status: "active", name: Faker.Commerce.product_name())
        |> Map.put(:action, :insert)
        |> Product.validate()

      assert changeset.valid? == false
      assert Keyword.keys(changeset.errors) == [:status]

      {_, error_info} = changeset.errors[:status]
      assert error_info[:code] == "cannot_be_active"
    end

    test "when given product with variants with valid active status" do
      account = account_fixture()
      product = product_fixture(account, %{kind: "with_variants"})
      product_fixture(account, %{kind: "variant", status: "active", parent_id: product.id})

      changeset =
        product
        |> change(status: "active")
        |> Product.validate()

      assert changeset.valid?
    end

    #
    # MARK: Product combo
    #
    test "when given product combo and missing required fields" do
      changeset =
        %Product{}
        |> change(kind: "combo")
        |> Map.put(:action, :insert)
        |> Product.validate()

      assert changeset.valid? == false
      assert Keyword.keys(changeset.errors) == [:name]
    end

    test "when given product combo with invalid internal status due to missing internal item" do
      changeset =
        %Product{}
        |> change(kind: "combo", status: "internal", name: Faker.Commerce.product_name())
        |> Map.put(:action, :insert)
        |> Product.validate()

      assert changeset.valid? == false
      assert Keyword.keys(changeset.errors) == [:status]

      {_, error_info} = changeset.errors[:status]
      assert error_info[:code] == "cannot_be_internal"
    end

    test "when given product combo with invalid internal status due to missing internal price" do
      account = account_fixture()
      product = product_fixture(account, %{kind: "combo"})
      product_fixture(account, %{kind: "item", status: "internal", parent_id: product.id})

      changeset =
        product
        |> change(status: "internal")
        |> Map.put(:action, :update)
        |> Product.validate()

      assert changeset.valid? == false
      assert Keyword.keys(changeset.errors) == [:status]

      {_, error_info} = changeset.errors[:status]
      assert error_info[:code] == "require_internal_price"
    end

    test "when given product combo with valid internal status" do
      account = account_fixture()
      product = product_fixture(account, %{kind: "combo"})
      price_fixture(account, product, %{status: "internal"})
      product_fixture(account, %{kind: "item", status: "internal", parent_id: product.id})

      changeset =
        product
        |> change(status: "internal")
        |> Product.validate()

      assert changeset.valid?
    end

    test "when given product combo with invalid active status due to missing active item" do
      changeset =
        %Product{}
        |> change(kind: "combo", status: "active", name: Faker.Commerce.product_name())
        |> Map.put(:action, :insert)
        |> Product.validate()

      assert changeset.valid? == false
      assert Keyword.keys(changeset.errors) == [:status]

      {_, error_info} = changeset.errors[:status]
      assert error_info[:code] == "cannot_be_active"
    end

    test "when given product combo with invalid active status due to missing active price" do
      account = account_fixture()
      product = product_fixture(account, %{kind: "combo"})
      product_fixture(account, %{kind: "item", status: "active", parent_id: product.id})

      changeset =
        product
        |> change(status: "active")
        |> Map.put(:action, :update)
        |> Product.validate()

      assert changeset.valid? == false
      assert Keyword.keys(changeset.errors) == [:status]

      {_, error_info} = changeset.errors[:status]
      assert error_info[:code] == "require_active_price"
    end

    test "when given product combo with valid active status" do
      account = account_fixture()
      product = product_fixture(account, %{kind: "combo"})
      price_fixture(account, product, %{status: "active"})
      product_fixture(account, %{kind: "item", status: "active", parent_id: product.id})

      changeset =
        product
        |> change(status: "active")
        |> Map.put(:action, :update)
        |> Product.validate()

      assert changeset.valid?
    end

    #
    # MARK: Product variant
    #
    test "when given product variant and missing required fields" do
      changeset =
        %Product{}
        |> change(kind: "variant")
        |> Map.put(:action, :insert)
        |> Product.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:name, :parent_id, :goods_id, :goods_type]
    end

    test "when given product varaint with invalid internal status due to missing internal price" do
      account = account_fixture()
      parent = product_fixture(account, %{kind: "with_variants"})
      stockable = stockable_fixture(account)

      changeset =
        %Product{}
        |> change(
          account_id: account.id,
          status: "internal",
          kind: "variant",
          parent_id: parent.id,
          name: Faker.Commerce.product_name(),
          goods_id: stockable.id,
          goods_type: "Stockable"
        )
        |> Map.put(:action, :insert)
        |> Product.validate()

      assert changeset.valid? == false
      assert Keyword.keys(changeset.errors) == [:status]

      {_, error_info} = changeset.errors[:status]
      assert error_info[:code] == "cannot_be_internal"
    end

    test "when given product varaint with valid internal status" do
      account = account_fixture()
      parent = product_fixture(account, %{kind: "with_variants"})
      variant = product_fixture(account, %{kind: "variant", parent_id: parent.id})
      price_fixture(account, variant, %{status: "internal"})

      changeset =
        variant
        |> change(status: "internal")
        |> Map.put(:action, :update)
        |> Product.validate()

      assert changeset.valid?
    end

    test "when given product varaint with invalid active status due to missing active price" do
      account = account_fixture()
      parent = product_fixture(account, %{kind: "with_variants"})
      stockable = stockable_fixture(account)

      changeset =
        %Product{}
        |> change(
          account_id: account.id,
          status: "active",
          kind: "variant",
          parent_id: parent.id,
          name: Faker.Commerce.product_name(),
          goods_id: stockable.id,
          goods_type: "Stockable"
        )
        |> Map.put(:action, :insert)
        |> Product.validate()

      assert changeset.valid? == false
      assert Keyword.keys(changeset.errors) == [:status]

      {_, error_info} = changeset.errors[:status]
      assert error_info[:code] == "cannot_be_active"
    end

    test "when given product varaint with valid active status" do
      account = account_fixture()
      parent = product_fixture(account, %{kind: "with_variants"})
      variant = product_fixture(account, %{kind: "variant", parent_id: parent.id})
      price_fixture(account, variant, %{status: "active"})

      changeset =
        variant
        |> change(status: "active")
        |> Map.put(:action, :update)
        |> Product.validate()

      assert changeset.valid?
    end

    #
    # MARK: Product item
    #
    test "when given product item and missing required fields" do
      changeset =
        %Product{}
        |> change(kind: "item")
        |> Map.put(:action, :insert)
        |> Product.validate()

      assert changeset.valid? == false
      assert Keyword.keys(changeset.errors) == [:name, :parent_id, :goods_id, :goods_type]
    end

    test "when given product item with valid internal status" do
      account = account_fixture()
      stockable = stockable_fixture(account)
      parent = product_fixture(account, %{kind: "combo"})

      changeset =
        change(%Product{}, %{
          account_id: account.id,
          account: account,
          status: "internal",
          kind: "item",
          parent_id: parent.id,
          name: Faker.Commerce.product_name(),
          goods_id: stockable.id,
          goods_type: "Stockable"
        })
        |> Map.put(:action, :insert)
        |> Product.validate()

      assert changeset.valid?
    end

    test "when given product item with valid active status" do
      account = account_fixture()
      stockable = stockable_fixture(account)
      parent = product_fixture(account, %{kind: "combo"})

      changeset =
        change(%Product{}, %{
          account_id: account.id,
          account: account,
          status: "active",
          kind: "item",
          parent_id: parent.id,
          name: Faker.Commerce.product_name(),
          goods_id: stockable.id,
          goods_type: "Stockable"
        })
        |> Map.put(:action, :insert)
        |> Product.validate()

      assert changeset.valid?
    end
  end

  describe "changeset/4" do
    test "when given name sync is sync with goods" do
      account = account_fixture()
      stockable = stockable_fixture(account)
      product = %Product{account_id: account.id, account: account}

      changeset = Product.changeset(product, :insert, %{
        name_sync: "sync_with_goods",
        goods_id: stockable.id,
        goods_type: "Stockable"
      })

      assert changeset.valid?
      assert changeset.changes[:name] == stockable.name
    end
  end
end
