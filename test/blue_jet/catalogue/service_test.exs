defmodule BlueJet.Catalogue.ServiceTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity.Account
  alias BlueJet.Goods.Stockable
  alias BlueJet.Catalogue.Service
  alias BlueJet.Catalogue.Product
  alias BlueJet.Catalogue.GoodsServiceMock

  setup :verify_on_exit!

  describe "list_product/2" do
    test "product for different account is not returned" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      Repo.insert!(%Product{
        account_id: account.id,
        name: Faker.Commerce.product_name()
      })
      Repo.insert!(%Product{
        account_id: account.id,
        name: Faker.Commerce.product_name()
      })
      Repo.insert!(%Product{
        account_id: other_account.id,
        name: Faker.Commerce.product_name()
      })

      products = Service.list_product(%{ account: account })
      assert length(products) == 2
    end

    test "pagination should change result size" do
      account = Repo.insert!(%Account{})
      Repo.insert!(%Product{
        account_id: account.id,
        name: Faker.Commerce.product_name()
      })
      Repo.insert!(%Product{
        account_id: account.id,
        name: Faker.Commerce.product_name()
      })
      Repo.insert!(%Product{
        account_id: account.id,
        name: Faker.Commerce.product_name()
      })
      Repo.insert!(%Product{
        account_id: account.id,
        name: Faker.Commerce.product_name()
      })
      Repo.insert!(%Product{
        account_id: account.id,
        name: Faker.Commerce.product_name()
      })

      products = Service.list_product(%{ account: account, pagination: %{ size: 3, number: 1 } })
      assert length(products) == 3

      products = Service.list_product(%{ account: account, pagination: %{ size: 3, number: 2 } })
      assert length(products) == 2
    end
  end

  describe "create_product/2" do
    test "when given invalid fields" do
      account = Repo.insert!(%Account{})
      fields = %{}

      {:error, changeset} = Service.create_product(fields, %{ account: account })

      assert changeset.valid? == false
    end

    test "when given valid fields" do
      account = Repo.insert!(%Account{})

      fields = %{
        "name" => Faker.Commerce.product_name(),
        "goods_id" => Ecto.UUID.generate(),
        "goods_type" => "Stockable"
      }

      GoodsServiceMock
      |> expect(:get_stockable, fn(_, _) ->
          %Stockable{ account_id: account.id }
         end)

      {:ok, product} = Service.create_product(fields, %{ account: account })

      assert product
    end
  end

  describe "get_product/2" do
    test "when given id" do
      account = Repo.insert!(%Account{})
      product = Repo.insert!(%Product{
        account_id: account.id,
        name: Faker.Commerce.product_name()
      })

      assert Service.get_product(%{ id: product.id }, %{ account: account })
    end

    test "when given id belongs to a different account" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      product = Repo.insert!(%Product{
        account_id: other_account.id,
        name: Faker.Commerce.product_name()
      })

      refute Service.get_product(%{ id: product.id }, %{ account: account })
    end

    test "when give id does not exist" do
      account = Repo.insert!(%Account{})

      refute Service.get_product(%{ id: Ecto.UUID.generate() }, %{ account: account })
    end
  end

  describe "update_product/2" do
    test "when given nil for product" do
      {:error, error} = Service.update_product(nil, %{}, %{})

      assert error == :not_found
    end

    test "when given id does not exist" do
      account = Repo.insert!(%Account{})

      {:error, error} = Service.update_product(Ecto.UUID.generate(), %{}, %{ account: account })

      assert error == :not_found
    end

    test "when given id belongs to a different account" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      product = Repo.insert!(%Product{
        account_id: other_account.id,
        name: Faker.Commerce.product_name()
      })

      {:error, error} = Service.update_product(product.id, %{}, %{ account: account })

      assert error == :not_found
    end

    test "when given valid id and valid fields" do
      account = Repo.insert!(%Account{})
      product = Repo.insert!(%Product{
        account_id: account.id,
        name: Faker.Commerce.product_name(),
        goods_id: Ecto.UUID.generate(),
        goods_type: "Stockable"
      })

      fields = %{
        "name" => Faker.Commerce.product_name()
      }

      {:ok, product} = Service.update_product(product.id, fields, %{ account: account })

      assert product
    end
  end

  describe "delete_product/2" do
    test "when given valid product" do
      account = Repo.insert!(%Account{})
      product = Repo.insert!(%Product{
        account_id: account.id,
        name: Faker.Commerce.product_name()
      })

      {:ok, product} = Service.delete_product(product, %{ account: account })

      assert product
      refute Repo.get(Product, product.id)
    end
  end
end