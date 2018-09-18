defmodule BlueJet.Catalogue.ServiceTest do
  use BlueJet.ContextCase

  import BlueJet.Catalogue.TestHelper
  import BlueJet.Goods.TestHelper

  alias BlueJet.Identity.Account
  alias BlueJet.Goods.Stockable
  alias BlueJet.Catalogue.DefaultService
  alias BlueJet.Catalogue.{Product, Price, ProductCollection, ProductCollectionMembership}
  alias BlueJet.Catalogue.GoodsServiceMock

  #
  # MARK: Product
  #
  describe "list_product/2 and count_product/2" do
    test "with valid request" do
      account1 = account_fixture()
      account2 = account_fixture()

      product1 = product_fixture(account1, %{label: "bestseller", name: "Cool Product", status: "active"})
      product2 = product_fixture(account1, %{label: "bestseller", name: "Best Product", status: "active"})
      product3 = product_fixture(account1, %{label: "bestseller", name: "Awesome Product", status: "active"})
      product4 = product_fixture(account1, %{name: "Best Product"})
      product_fixture(account1, %{label: "bestseller", name: "Test Product"})
      product_fixture(account2, %{label: "bestseller", name: "Test Product"})

      collection = product_collection_fixture(account1)
      product_collection_membership_fixture(account1, product1, collection)
      product_collection_membership_fixture(account1, product2, collection)
      product_collection_membership_fixture(account1, product3, collection)
      product_collection_membership_fixture(account1, product4, collection)

      query = %{search: "product", filter: %{label: "bestseller", collection_id: collection.id}}
      opts = %{
        account: account1,
        pagination: %{size: 2, number: 1},
        preload: %{paths: [:prices]}
      }
      products = DefaultService.list_product(query, opts)

      assert length(products) == 2
      assert length(Enum.at(products, 0).prices) == 1

      opts = %{
        account: account1,
        pagination: %{size: 2, number: 2}
      }
      products = DefaultService.list_product(query, opts)

      assert length(products) == 1

      assert DefaultService.count_product(query, %{account: account1}) == 3
      assert DefaultService.count_product(%{account: account1}) == 5
    end
  end

  describe "create_product/2" do
    test "when given invalid fields" do
      account = %Account{id: UUID.generate()}

      {:error, %{errors: errors}} = DefaultService.create_product(%{}, %{account: account})

      assert match_keys(errors, [:name, :goods_id, :goods_type])
    end

    test "when given valid fields" do
      account = account_fixture()
      stockable = stockable_fixture(account)

      fields = %{
        "name" => stockable.name,
        "goods_id" => stockable.id,
        "goods_type" => "Stockable"
      }

      {:ok, product} = DefaultService.create_product(fields, %{account: account})

      assert product.name == stockable.name
      assert product.goods_id == stockable.id
      assert product.goods_type == "Stockable"
    end
  end

  describe "get_product/2" do
    test "when given id doesn't exist" do
      account = account_fixture()

      refute DefaultService.get_product(%{id: UUID.generate()}, %{account: account})
    end

    test "when given id belongs to a different account" do
      account1 = account_fixture()
      account2 = account_fixture()
      product = product_fixture(account2)

      refute DefaultService.get_product(%{id: product.id}, %{account: account1})
    end

    test "when given id is valid" do
      account = account_fixture()
      target_product = product_fixture(account, %{status: "active"})

      identifiers = %{id: target_product.id}
      opts = %{account: account, preload: %{paths: [:prices]}}

      product = DefaultService.get_product(identifiers, opts)

      assert product.id == target_product.id
      assert length(product.prices) == 1
    end
  end

  describe "update_product/3" do
    test "when given id does not exist" do
      account = %Account{id: UUID.generate()}

      {:error, :not_found} = DefaultService.update_product(%{id: UUID.generate()}, %{}, %{account: account})
    end

    test "when given id belongs to a different account" do
      account1 = account_fixture()
      account2 = account_fixture()
      product = product_fixture(account2)

      {:error, :not_found} = DefaultService.update_product(%{id: product.id}, %{}, %{account: account1})
    end

    test "when given valid id and valid fields" do
      account = account_fixture()
      target_product = product_fixture(account)

      identifiers = %{id: target_product.id}
      fields = %{"name" => Faker.Commerce.product_name()}
      opts = %{account: account}

      {:ok, product} = DefaultService.update_product(identifiers, fields, opts)

      assert product.id == target_product.id
      assert product.name == fields["name"]
    end
  end

  describe "delete_product/2" do
    test "when given invalid id" do
      account = %Account{id: UUID.generate()}

      {:error, :not_found} = DefaultService.delete_product(%{id: UUID.generate()}, %{account: account})
    end

    test "when given id belongs to a different account" do
      account1 = account_fixture()
      account2 = account_fixture()
      product = product_fixture(account2)

      {:error, :not_found} = DefaultService.delete_product(%{id: product.id}, %{account: account1})
    end

    test "when given valid id" do
      account = account_fixture()
      product = product_fixture(account)

      {:ok, _} = DefaultService.delete_product(%{id: product.id}, %{account: account})

      refute Repo.get(Product, product.id)
    end
  end

  #
  # MARK: Price
  #
  describe "list_price/2 and count_price/2" do
    test "with valid request" do
      account1 = account_fixture()
      account2 = account_fixture()

      product1 = product_fixture(account1)
      product2 = product_fixture(account1)
      product3 = product_fixture(account2)

      price_fixture(account1, product1)
      price_fixture(account1, product1)
      price_fixture(account1, product1)
      price_fixture(account1, product2)
      price_fixture(account2, product3)

      query = %{filter: %{product_id: product1.id}}
      opts = %{
        account: account1,
        pagination: %{size: 2, number: 1},
        preload: %{paths: [:product]}
      }
      prices = DefaultService.list_price(query, opts)

      assert length(prices) == 2
      assert Enum.at(prices, 0).product.id

      opts = %{
        account: account1,
        pagination: %{size: 2, number: 2}
      }
      prices = DefaultService.list_price(query, opts)

      assert length(prices) == 1

      assert DefaultService.count_price(query, %{account: account1}) == 3
      assert DefaultService.count_price(%{account: account1}) == 4
    end
  end

  describe "create_price/2" do
    test "when given invalid fields" do
      account = %Account{id: UUID.generate()}

      {:error, %{errors: errors}} = DefaultService.create_price(%{}, %{account: account})

      assert match_keys(errors, [:name, :product_id, :charge_amount_cents, :charge_unit])
    end

    test "when given valid fields" do
      account = account_fixture()
      product = product_fixture(account)

      fields = %{
        "name" => Faker.String.base64(12),
        "product_id" => product.id,
        "charge_amount_cents" => System.unique_integer([:positive]),
        "charge_unit" => Faker.String.base64(2)
      }

      {:ok, price} = DefaultService.create_price(fields, %{account: account})

      assert price.name == fields["name"]
      assert price.product_id == fields["product_id"]
      assert price.charge_amount_cents == fields["charge_amount_cents"]
      assert price.charge_unit == fields["charge_unit"]
    end
  end

  describe "get_price/2" do
    test "when given id doesn't exist" do
      account = account_fixture()

      refute DefaultService.get_price(%{id: UUID.generate()}, %{account: account})
    end

    test "when given id belongs to a different account" do
      account1 = account_fixture()
      account2 = account_fixture()
      product = product_fixture(account2)
      price = price_fixture(account2, product)

      refute DefaultService.get_product(%{id: price.id}, %{account: account1})
    end

    test "when given id is valid" do
      account = account_fixture()
      product = product_fixture(account)
      target_price = price_fixture(account, product)

      identifiers = %{id: target_price.id}
      opts = %{account: account, preload: %{paths: [:product]}}

      price = DefaultService.get_price(identifiers, opts)

      assert price.id == target_price.id
      assert price.product.id
    end
  end

  describe "update_price/3" do
    test "when given id does not exist" do
      account = %Account{id: UUID.generate()}

      {:error, :not_found} = DefaultService.update_price(%{id: UUID.generate()}, %{}, %{account: account})
    end

    test "when given id belongs to a different account" do
      account1 = account_fixture()
      account2 = account_fixture()
      product = product_fixture(account2)
      price = price_fixture(account2, product)

      {:error, :not_found} = DefaultService.update_product(%{id: price.id}, %{}, %{account: account1})
    end

    test "when given valid id and valid fields" do
      account = account_fixture()
      product = product_fixture(account)
      target_price = price_fixture(account, product)

      identifiers = %{id: target_price.id}
      fields = %{"name" => Faker.String.base64(12)}
      opts = %{account: account}

      {:ok, price} = DefaultService.update_price(identifiers, fields, opts)

      assert price.id == target_price.id
      assert price.name == fields["name"]
    end
  end

  describe "delete_price/2" do
    test "when given invalid id" do
      account = %Account{id: UUID.generate()}

      {:error, :not_found} = DefaultService.delete_price(%{id: UUID.generate()}, %{account: account})
    end

    test "when given id belongs to a different account" do
      account1 = account_fixture()
      account2 = account_fixture()
      product = product_fixture(account2)
      price = price_fixture(account2, product)

      {:error, :not_found} = DefaultService.delete_price(%{id: price.id}, %{account: account1})
    end

    test "when given valid id" do
      account = account_fixture()
      product = product_fixture(account)
      price = price_fixture(account, product)

      {:ok, _} = DefaultService.delete_price(%{id: price.id}, %{account: account})

      refute Repo.get(Price, price.id)
    end
  end

  #
  # MARK: Product Collection
  #
  describe "list_product_collection/2 and count_product_collection/2" do
    test "with valid request" do
      account1 = account_fixture()
      account2 = account_fixture()

      product_collection_fixture(account1, %{label: "bestseller", name: "Cool Product"})
      product_collection_fixture(account1, %{label: "bestseller", name: "Best Product"})
      product_collection_fixture(account1, %{label: "bestseller", name: "Awesome Product"})
      product_collection_fixture(account1, %{name: "Best Product"})
      product_collection_fixture(account2, %{label: "bestseller", name: "Test Product"})

      query = %{search: "product", filter: %{label: "bestseller"}}
      opts = %{
        account: account1,
        pagination: %{size: 2, number: 1}
      }
      collections = DefaultService.list_product_collection(query, opts)

      assert length(collections) == 2

      opts = %{
        account: account1,
        pagination: %{size: 2, number: 2}
      }
      collections = DefaultService.list_product_collection(query, opts)

      assert length(collections) == 1

      assert DefaultService.count_product_collection(query, %{account: account1}) == 3
      assert DefaultService.count_product_collection(%{account: account1}) == 4
    end
  end

  describe "create_product_collection/2" do
    test "when given invalid fields" do
      account = %Account{id: UUID.generate()}

      {:error, %{errors: errors}} = DefaultService.create_product_collection(%{}, %{account: account})

      assert match_keys(errors, [:name])
    end

    test "when given valid fields" do
      account = account_fixture()

      fields = %{"name" => Faker.Commerce.product_name()}

      {:ok, product_collection} = DefaultService.create_product_collection(fields, %{account: account})

      assert product_collection.name == fields["name"]
    end
  end

  describe "get_product_collection/2" do
    test "when given id does not exist" do
      account = %Account{id: UUID.generate()}

      refute DefaultService.get_product_collection(%{id: UUID.generate()}, %{account: account})
    end

    test "when given id belongs to a different account" do
      account1 = account_fixture()
      account2 = account_fixture()

      collection = product_collection_fixture(account2)

      refute DefaultService.get_product_collection(%{id: collection.id}, %{account: account1})
    end

    test "when given valid id" do
      account = account_fixture()
      collection = product_collection_fixture(account)

      assert DefaultService.get_product_collection(%{id: collection.id}, %{account: account})
    end
  end

  describe "update_product_collection/2" do
    test "when given id does not exist" do
      account = %Account{id: UUID.generate()}

      identifiers = %{id: UUID.generate()}
      opts = %{account: account}

      {:error, :not_found} = DefaultService.update_product_collection(identifiers, %{}, opts)
    end

    test "when given id belongs to a different account" do
      account1 = account_fixture()
      account2 = account_fixture()

      collection = product_collection_fixture(account2)

      identifiers = %{id: collection.id}
      opts = %{account: account1}

      {:error, :not_found} = DefaultService.update_product_collection(identifiers, %{}, opts)
    end

    test "when given valid id and valid fields" do
      account = account_fixture()
      collection = product_collection_fixture(account)

      identifiers = %{id: collection.id}
      fields = %{"name" => Faker.Commerce.product_name()}
      opts = %{account: account}

      {:ok, collection} = DefaultService.update_product_collection(identifiers, fields, opts)

      assert collection.name == fields["name"]
    end
  end

  describe "delete_product_collection/2" do
    test "when given id does not exist" do
      account = %Account{id: UUID.generate()}

      identifiers = %{id: UUID.generate()}
      opts = %{account: account}

      {:error, :not_found} = DefaultService.delete_product_collection(identifiers, opts)
    end

    test "when given id belongs to a different account" do
      account1 = account_fixture()
      account2 = account_fixture()

      collection = product_collection_fixture(account2)

      identifiers = %{id: collection.id}
      opts = %{account: account1}

      {:error, :not_found} = DefaultService.delete_product_collection(identifiers, opts)
    end

    test "when given valid id" do
      account = account_fixture()
      collection = product_collection_fixture(account)

      identifiers = %{id: collection.id}
      opts = %{account: account}

      {:ok, _} = DefaultService.delete_product_collection(identifiers, opts)

      refute Repo.get(ProductCollection, collection.id)
    end
  end

  describe "list_product_collection_membership/2 and count_product_collection_membership/2" do
    test "with valid request" do
      account = account_fixture()

      product1 = product_fixture(account, %{name: "Cool Product", status: "active"})
      product2 = product_fixture(account, %{name: "Best Product", status: "active"})
      product3 = product_fixture(account, %{name: "Awesome Product", status: "active"})
      product4 = product_fixture(account, %{name: "Something good", status: "active"})
      product5 = product_fixture(account, %{name: "Something good"})
      product6 = product_fixture(account, %{name: "Test Product"})

      collection1 = product_collection_fixture(account)
      collection2 = product_collection_fixture(account)

      product_collection_membership_fixture(account, product1, collection1)
      product_collection_membership_fixture(account, product2, collection1)
      product_collection_membership_fixture(account, product3, collection1)
      product_collection_membership_fixture(account, product4, collection1)
      product_collection_membership_fixture(account, product5, collection1)
      product_collection_membership_fixture(account, product6, collection2)

      query = %{search: "product", filter: %{product_status: "active", collection_id: collection1.id}}
      opts = %{
        account: account,
        pagination: %{size: 2, number: 1},
        preload: %{paths: [:product]}
      }
      memberships = DefaultService.list_product_collection_membership(query, opts)

      assert length(memberships) == 2
      assert Enum.at(memberships, 0).product.id

      opts = %{
        account: account,
        pagination: %{size: 2, number: 2}
      }
      memberships = DefaultService.list_product_collection_membership(query, opts)

      assert length(memberships) == 1

      assert DefaultService.count_product_collection_membership(query, %{account: account}) == 3
      assert DefaultService.count_product_collection_membership(%{account: account}) == 6
    end
  end
end