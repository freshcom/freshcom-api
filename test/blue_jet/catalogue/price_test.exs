defmodule BlueJet.Catalogue.PriceTest do
  use BlueJet.DataCase

  import Mox

  alias BlueJet.Identity.Account
  alias BlueJet.Catalogue.{Product, Price}
  alias BlueJet.Catalogue.IdentityServiceMock

  describe "schema" do
    test "defaults" do
      price = %Price{}

      assert price.status == "draft"
      assert price.currency_code == "CAD"
      assert price.estimate_by_default == false
      assert price.minimum_order_quantity == 1
      assert price.tax_one_percentage == Decimal.new(0)
      assert price.tax_two_percentage == Decimal.new(0)
      assert price.tax_three_percentage == Decimal.new(0)
      assert price.custom_data == %{}
      assert price.translations == %{}
    end

    test "when product is deleted price should be automatically deleted" do
      account = Repo.insert!(%Account{})
      product = Repo.insert!(%Product{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      price = Repo.insert!(%Price{
        account_id: account.id,
        product_id: product.id,
        name: Faker.String.base64(5),
        charge_amount_cents: 500,
        charge_unit: Faker.String.base64(2),
        order_unit: Faker.String.base64(2)
      })

      Repo.delete!(product)
      refute Repo.get(Price, price.id)
    end

    test "when parent is deleted price should be automatically deleted" do
      account = Repo.insert!(%Account{})
      product = Repo.insert!(%Product{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      parent = Repo.insert!(%Price{
        account_id: account.id,
        product_id: product.id,
        name: Faker.String.base64(5),
        charge_amount_cents: 500,
        charge_unit: Faker.String.base64(2),
        order_unit: Faker.String.base64(2)
      })
      price = Repo.insert!(%Price{
        account_id: account.id,
        product_id: product.id,
        parent_id: parent.id,
        name: Faker.String.base64(5),
        charge_amount_cents: 500,
        charge_unit: Faker.String.base64(2),
        order_unit: Faker.String.base64(2)
      })

      Repo.delete!(parent)
      refute Repo.get(Price, price.id)
    end
  end

  test "writable_fields/0" do
    assert Price.writable_fields() == [
      :status,
      :code,
      :name,
      :label,
      :currency_code,
      :charge_amount_cents,
      :charge_unit,
      :order_unit,
      :estimate_by_default,
      :estimate_average_percentage,
      :estimate_maximum_percentage,
      :minimum_order_quantity,
      :tax_one_percentage,
      :tax_two_percentage,
      :tax_three_percentage,
      :start_time,
      :end_time,
      :caption,
      :description,
      :custom_data,
      :translations,
      :product_id,
      :parent_id
    ]
  end

  describe "validate/1" do
    test "when given price missing required fields" do
      changeset =
        change(%Price{}, %{})
        |> Price.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:name, :product_id, :charge_amount_cents, :charge_unit]
    end

    test "when given invalid active status due to already existing price with same minimum order quantity" do
      account = Repo.insert!(%Account{})
      product = Repo.insert!(%Product{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      Repo.insert!(%Price{
        account_id: account.id,
        product_id: product.id,
        status: "active",
        name: Faker.String.base64(5),
        charge_amount_cents: 500,
        order_unit: Faker.String.base64(2),
        charge_unit: Faker.String.base64(2)
      })
      price = %Price{
        account_id: account.id,
        product_id: product.id,
        name: Faker.String.base64(5),
        charge_amount_cents: 500,
        order_unit: Faker.String.base64(2),
        charge_unit: Faker.String.base64(2)
      }
      changeset =
        change(price, %{ status: "active" })
        |> Price.validate()

      refute changeset.valid?

      assert Keyword.keys(changeset.errors) == [:status]

      {_, error_info} = changeset.errors[:status]
      assert error_info[:validation] == :minimum_order_quantity_taken
    end

    test "when given invalid draft status due to internal product require a internal price" do
      account = Repo.insert!(%Account{})
      product = Repo.insert!(%Product{
        account_id: account.id,
        status: "internal",
        name: Faker.String.base64(5)
      })
      price = %Price{
        id: Ecto.UUID.generate(),
        account_id: account.id,
        product_id: product.id,
        status: "internal",
        name: Faker.String.base64(5),
        charge_amount_cents: 500,
        order_unit: Faker.String.base64(2),
        charge_unit: Faker.String.base64(2)
      }
      changeset =
        change(price, %{ status: "draft" })
        |> Price.validate()

      refute changeset.valid?

      {_, error_info} = changeset.errors[:status]
      assert error_info[:validation] == :internal_product_depends_on_internal_price
    end

    test "when given invalid draft status due to active product require an active price" do
      account = Repo.insert!(%Account{})
      product = Repo.insert!(%Product{
        account_id: account.id,
        status: "active",
        name: Faker.String.base64(5)
      })
      price = %Price{
        id: Ecto.UUID.generate(),
        account_id: account.id,
        product_id: product.id,
        status: "active",
        name: Faker.String.base64(5),
        charge_amount_cents: 500,
        order_unit: Faker.String.base64(2),
        charge_unit: Faker.String.base64(2)
      }
      changeset =
        change(price, %{ status: "draft" })
        |> Price.validate()

      refute changeset.valid?

      {_, error_info} = changeset.errors[:status]
      assert error_info[:validation] == :active_product_depends_on_active_price
    end
  end

  describe "changeset/4" do
    test "when child attributes is different from parent status" do
      account = Repo.insert!(%Account{})
      product = Repo.insert!(%Product{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      price = Repo.insert!(%Price{
        account_id: account.id,
        product_id: product.id,
        status: "active",
        label: "regular",
        name: Faker.String.base64(5),
        charge_amount_cents: 500,
        charge_unit: "CU",
        order_unit: "OU",
        minimum_order_quantity: 6
      })

      IdentityServiceMock
      |> expect(:get_account, fn(_) -> account end)

      changeset = Price.changeset(%Price{ account_id: account.id }, :insert, %{
        product_id: product.id,
        parent_id: price.id
      })

      assert changeset.changes[:status] == "active"
      assert changeset.changes[:label] == "regular"
      assert changeset.changes[:charge_unit] == "CU"
      assert changeset.changes[:minimum_order_quantity] == 6
    end

    test "when given price is not estimate by default" do
      IdentityServiceMock
      |> expect(:get_account, fn(_) -> %Account{} end)

      changeset = Price.changeset(%Price{ account_id: Ecto.UUID.generate() }, :insert, %{
        product_id: Ecto.UUID.generate(),
        charge_unit: "CU"
      })

      assert changeset.changes[:order_unit] == "CU"
    end

    test "when given price is estimate by default" do
      IdentityServiceMock
      |> expect(:get_account, fn(_) -> %Account{} end)

      changeset = Price.changeset(%Price{ account_id: Ecto.UUID.generate() }, :insert, %{
        product_id: Ecto.UUID.generate(),
        estimate_by_default: true,
        charge_unit: "CU"
      })

      refute changeset.changes[:order_unit]
    end

    test "when given locale is different than default_locale" do
      IdentityServiceMock
      |> expect(:get_account, fn(_) -> %Account{} end)

      changeset = Price.changeset(%Price{ account_id: Ecto.UUID.generate() }, :update, %{
        name: Faker.String.base64(5),
        charge_unit: Faker.String.base64(2),
        order_unit: Faker.String.base64(2)
      }, "en", "zh-CN")

      assert Map.keys(changeset.changes) == [:translations]
    end
  end

  describe "balance/1" do
    test "when price charge_amount_cents is different than the sum of children" do
      account = Repo.insert!(%Account{})
      product = Repo.insert!(%Product{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      price = Repo.insert!(%Price{
        account_id: account.id,
        product_id: product.id,
        name: Faker.String.base64(5),
        charge_amount_cents: 100,
        order_unit: Faker.String.base64(2),
        charge_unit: Faker.String.base64(2)
      })
      Repo.insert!(%Price{
        account_id: account.id,
        product_id: product.id,
        parent_id: price.id,
        name: Faker.String.base64(5),
        charge_amount_cents: 200,
        order_unit: Faker.String.base64(2),
        charge_unit: Faker.String.base64(2)
      })
      Repo.insert!(%Price{
        account_id: account.id,
        product_id: product.id,
        parent_id: price.id,
        name: Faker.String.base64(5),
        charge_amount_cents: 800,
        order_unit: Faker.String.base64(2),
        charge_unit: Faker.String.base64(2)
      })

      price = Price.balance(price)

      assert price.charge_amount_cents == 1000
    end
  end
end
