defmodule BlueJet.Catalogue.ProductTest do
  use BlueJet.DataCase

  alias BlueJet.Identity.Account
  alias BlueJet.Goods.Stockable
  alias BlueJet.Catalogue.Product
  alias BlueJet.Catalogue.Price

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

    test "when parent is deleted variant should be automatically deleted" do
      account = Repo.insert!(%Account{})
      product_with_variants = Repo.insert!(%Product{
        kind: "with_variants",
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      product_variant = Repo.insert!(%Product{
        account_id: account.id,
        parent_id: product_with_variants.id,
        kind: "variant",
        name: Faker.String.base64(5)
      })

      Repo.delete!(product_with_variants)
      refute Repo.get(Product, product_variant.id)
    end

    test "when parent is deleted item should be automatically deleted" do
      account = Repo.insert!(%Account{})
      product_combo = Repo.insert!(%Product{
        kind: "combo",
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      product_item = Repo.insert!(%Product{
        account_id: account.id,
        parent_id: product_combo.id,
        kind: "item",
        name: Faker.String.base64(5)
      })

      Repo.delete!(product_combo)
      refute Repo.get(Product, product_item.id)
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

    test "when given product with variants with invalid internal status due to missing internal variant" do
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

    test "when given product with variants with valid internal status" do
      account = Repo.insert!(%Account{})
      product_with_variants = Repo.insert!(%Product{
        account_id: account.id,
        kind: "with_variants",
        name: Faker.String.base64(5)
      })
      Repo.insert!(%Product{
        account_id: account.id,
        parent_id: product_with_variants.id,
        kind: "variant",
        status: "internal",
        name: Faker.String.base64(5)
      })

      changeset =
        change(product_with_variants, %{
          status: "internal"
        })
        |> Product.validate()

      assert changeset.valid?
    end

    test "when given product with variants with invalid active status due to missing active variant" do
      changeset =
        change(%Product{}, %{
          kind: "with_variants",
          name: Faker.String.base64(5),
          status: "active"
        })
        |> Product.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:status]

      {_, error_info} = changeset.errors[:status]
      assert error_info[:validation] == "require_primary_active_variant"
    end

    test "when given product with variants with valid active status" do
      account = Repo.insert!(%Account{})
      product_with_variants = Repo.insert!(%Product{
        account_id: account.id,
        kind: "with_variants",
        name: Faker.String.base64(5)
      })
      Repo.insert!(%Product{
        account_id: account.id,
        parent_id: product_with_variants.id,
        primary: true,
        kind: "variant",
        status: "active",
        name: Faker.String.base64(5)
      })

      changeset =
        change(product_with_variants, %{
          status: "active"
        })
        |> Product.validate()

      assert changeset.valid?
    end

    #
    # MARK: Product combo
    #
    test "when given product combo and missing required fields" do
      changeset =
        change(%Product{}, %{ kind: "combo" })
        |> Product.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:name]
    end

    test "when given product combo with invalid internal status due to missing internal item" do
      changeset =
        change(%Product{}, %{
          kind: "combo",
          name: Faker.String.base64(5),
          status: "internal"
        })
        |> Product.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:status]

      {_, error_info} = changeset.errors[:status]
      assert error_info[:validation] == "require_internal_item"
    end

    test "when given product combo with invalid internal status due to missing internal price" do
      account = Repo.insert!(%Account{})
      product_combo = Repo.insert!(%Product{
        account_id: account.id,
        kind: "combo",
        name: Faker.String.base64(5)
      })
      Repo.insert!(%Product{
        account_id: account.id,
        parent_id: product_combo.id,
        kind: "item",
        status: "internal",
        name: Faker.String.base64(5)
      })

      changeset =
        change(product_combo, %{
          status: "internal"
        })
        |> Product.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:status]

      {_, error_info} = changeset.errors[:status]
      assert error_info[:validation] == "require_internal_price"
    end

    test "when given product combo with valid internal status" do
      account = Repo.insert!(%Account{})
      product_combo = Repo.insert!(%Product{
        account_id: account.id,
        kind: "combo",
        name: Faker.String.base64(5)
      })
      Repo.insert!(%Price{
        account_id: account.id,
        product_id: product_combo.id,
        status: "internal",
        charge_amount_cents: 500,
        charge_unit: Faker.String.base64(2),
        order_unit: Faker.String.base64(2),
        name: Faker.String.base64(5)
      })
      Repo.insert!(%Product{
        account_id: account.id,
        parent_id: product_combo.id,
        kind: "item",
        status: "internal",
        name: Faker.String.base64(5)
      })

      changeset =
        change(product_combo, %{
          status: "internal"
        })
        |> Product.validate()

      assert changeset.valid?
    end

    test "when given product combo with invalid active status due to missing active item" do
      changeset =
        change(%Product{}, %{
          kind: "combo",
          name: Faker.String.base64(5),
          status: "active"
        })
        |> Product.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:status]

      {_, error_info} = changeset.errors[:status]
      assert error_info[:validation] == "require_active_item"
    end

    test "when given product combo with invalid active status due to missing active price" do
      account = Repo.insert!(%Account{})
      product_combo = Repo.insert!(%Product{
        account_id: account.id,
        kind: "combo",
        name: Faker.String.base64(5)
      })
      Repo.insert!(%Product{
        account_id: account.id,
        parent_id: product_combo.id,
        kind: "item",
        status: "active",
        name: Faker.String.base64(5)
      })

      changeset =
        change(product_combo, %{
          status: "active"
        })
        |> Product.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:status]

      {_, error_info} = changeset.errors[:status]
      assert error_info[:validation] == "require_active_price"
    end

    test "when given product combo with valid active status" do
      account = Repo.insert!(%Account{})
      product_combo = Repo.insert!(%Product{
        account_id: account.id,
        kind: "combo",
        name: Faker.String.base64(5)
      })
      Repo.insert!(%Price{
        account_id: account.id,
        product_id: product_combo.id,
        status: "active",
        charge_amount_cents: 500,
        charge_unit: Faker.String.base64(2),
        order_unit: Faker.String.base64(2),
        name: Faker.String.base64(5)
      })
      Repo.insert!(%Product{
        account_id: account.id,
        parent_id: product_combo.id,
        kind: "item",
        status: "active",
        name: Faker.String.base64(5)
      })

      changeset =
        change(product_combo, %{
          status: "active"
        })
        |> Product.validate()

      assert changeset.valid?
    end

    #
    # MARK: Product variant
    #
    test "when given product variant and missing required fields" do
      changeset =
        change(%Product{}, %{ kind: "variant" })
        |> Product.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:name, :parent_id, :source_id, :source_type]
    end

    test "when given product varaint with invalid internal status due to missing internal price" do
      account = Repo.insert!(%Account{})
      stockable = Repo.insert!(%Stockable{
        account_id: account.id,
        name: Faker.String.base64(5),
        unit_of_measure: Faker.String.base64(2)
      })
      product_with_variants = Repo.insert!(%Product{
        account_id: account.id,
        kind: "with_variants",
        name: Faker.String.base64(5)
      })
      changeset =
        change(%Product{}, %{
          account_id: account.id,
          status: "internal",
          kind: "variant",
          parent_id: product_with_variants.id,
          name: Faker.String.base64(5),
          source_id: stockable.id,
          source_type: "Stockable"
        })
        |> Product.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:status]

      {_, error_info} = changeset.errors[:status]
      assert error_info[:validation] == "require_internal_price"
    end

    test "when given product varaint with valid internal status" do
      account = Repo.insert!(%Account{})
      stockable = Repo.insert!(%Stockable{
        account_id: account.id,
        name: Faker.String.base64(5),
        unit_of_measure: Faker.String.base64(2)
      })
      product_with_variants = Repo.insert!(%Product{
        account_id: account.id,
        kind: "with_variants",
        name: Faker.String.base64(5)
      })
      product_variant = Repo.insert!(%Product{
        account_id: account.id,
        kind: "variant",
        parent_id: product_with_variants.id,
        name: Faker.String.base64(5),
        source_id: stockable.id,
        source_type: "Stockable"
      })
      Repo.insert!(%Price{
        account_id: account.id,
        product_id: product_variant.id,
        status: "internal",
        charge_amount_cents: 500,
        charge_unit: Faker.String.base64(2),
        order_unit: Faker.String.base64(2),
        name: Faker.String.base64(5)
      })
      changeset =
        change(product_variant, %{ status: "internal" })
        |> Product.validate()

      assert changeset.valid?
    end

    test "when given product varaint with invalid active status due to missing internal price" do
      account = Repo.insert!(%Account{})
      stockable = Repo.insert!(%Stockable{
        account_id: account.id,
        name: Faker.String.base64(5),
        unit_of_measure: Faker.String.base64(2)
      })
      product_with_variants = Repo.insert!(%Product{
        account_id: account.id,
        kind: "with_variants",
        name: Faker.String.base64(5)
      })
      changeset =
        change(%Product{}, %{
          account_id: account.id,
          status: "active",
          kind: "variant",
          parent_id: product_with_variants.id,
          name: Faker.String.base64(5),
          source_id: stockable.id,
          source_type: "Stockable"
        })
        |> Product.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:status]

      {_, error_info} = changeset.errors[:status]
      assert error_info[:validation] == "require_active_price"
    end

    test "when given product varaint with valid active status" do
      account = Repo.insert!(%Account{})
      stockable = Repo.insert!(%Stockable{
        account_id: account.id,
        name: Faker.String.base64(5),
        unit_of_measure: Faker.String.base64(2)
      })
      product_with_variants = Repo.insert!(%Product{
        account_id: account.id,
        kind: "with_variants",
        name: Faker.String.base64(5)
      })
      product_variant = Repo.insert!(%Product{
        account_id: account.id,
        kind: "variant",
        parent_id: product_with_variants.id,
        name: Faker.String.base64(5),
        source_id: stockable.id,
        source_type: "Stockable"
      })
      Repo.insert!(%Price{
        account_id: account.id,
        product_id: product_variant.id,
        status: "active",
        charge_amount_cents: 500,
        charge_unit: Faker.String.base64(2),
        order_unit: Faker.String.base64(2),
        name: Faker.String.base64(5)
      })
      changeset =
        change(product_variant, %{ status: "active" })
        |> Product.validate()

      assert changeset.valid?
    end

    #
    # MARK: Product item
    #
    test "when given product item and missing required fields" do
      changeset =
        change(%Product{}, %{ kind: "item" })
        |> Product.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:name, :parent_id, :source_id, :source_type]
    end

    test "when given product item with valid internal status" do
      account = Repo.insert!(%Account{})
      stockable = Repo.insert!(%Stockable{
        account_id: account.id,
        name: Faker.String.base64(5),
        unit_of_measure: Faker.String.base64(2)
      })
      product_combo = Repo.insert!(%Product{
        account_id: account.id,
        kind: "combo",
        name: Faker.String.base64(5)
      })
      changeset =
        change(%Product{}, %{
          account_id: account.id,
          status: "internal",
          kind: "item",
          parent_id: product_combo.id,
          name: Faker.String.base64(5),
          source_id: stockable.id,
          source_type: "Stockable"
        })
        |> Product.validate()

      assert changeset.valid?
    end

    test "when given product item with valid active status" do
      account = Repo.insert!(%Account{})
      stockable = Repo.insert!(%Stockable{
        account_id: account.id,
        name: Faker.String.base64(5),
        unit_of_measure: Faker.String.base64(2)
      })
      product_combo = Repo.insert!(%Product{
        account_id: account.id,
        kind: "combo",
        name: Faker.String.base64(5)
      })
      changeset =
        change(%Product{}, %{
          account_id: account.id,
          status: "active",
          kind: "item",
          parent_id: product_combo.id,
          name: Faker.String.base64(5),
          source_id: stockable.id,
          source_type: "Stockable"
        })
        |> Product.validate()

      assert changeset.valid?
    end
  end

  describe "changeset/4" do
    test "when given name sync is sync with source" do
      account = Repo.insert!(%Account{})
      stockable = Repo.insert!(%Stockable{
        account_id: account.id,
        name: Faker.String.base64(5),
        unit_of_measure: Faker.String.base64(2)
      })
      changeset = Product.changeset(%Product{ account_id: account.id, }, %{
        name_sync: "sync_with_source",
        source_id: stockable.id,
        source_type: "Stockable"
      })

      assert changeset.valid?
      assert changeset.changes[:name] == stockable.name
    end
  end
end
