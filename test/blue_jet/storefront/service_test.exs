defmodule BlueJet.Storefront.ServiceTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity.Account
  alias BlueJet.Crm.Customer
  alias BlueJet.Catalogue.Product
  alias BlueJet.Goods.Unlockable

  alias BlueJet.Storefront.{CrmServiceMock, CatalogueServiceMock, BalanceServiceMock}
  alias BlueJet.Storefront.Service
  alias BlueJet.Storefront.{Order, OrderLineItem, Unlock}

  describe "list_order/2" do
    test "order for different account is not returned" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      Repo.insert!(%Order{ account_id: account.id, status: "opened" })
      Repo.insert!(%Order{ account_id: account.id, status: "opened" })
      Repo.insert!(%Order{ account_id: other_account.id, status: "opened" })

      orders = Service.list_order(%{ account: account })
      assert length(orders) == 2
    end

    test "pagination should change result size" do
      account = Repo.insert!(%Account{})
      Repo.insert!(%Order{ account_id: account.id, status: "opened" })
      Repo.insert!(%Order{ account_id: account.id, status: "opened" })
      Repo.insert!(%Order{ account_id: account.id, status: "opened" })
      Repo.insert!(%Order{ account_id: account.id, status: "opened" })
      Repo.insert!(%Order{ account_id: account.id, status: "opened" })

      orders = Service.list_order(%{ account: account, pagination: %{ size: 3, number: 1 } })
      assert length(orders) == 3

      orders = Service.list_order(%{ account: account, pagination: %{ size: 3, number: 2 } })
      assert length(orders) == 2
    end

    test "preload should load related resource" do
      account = Repo.insert!(%Account{})
      customer = Repo.insert!(%Customer{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      product = Repo.insert!(%Product{
        account_id: account.id,
        name: Faker.Commerce.product_name()
      })
      target_order = Repo.insert!(%Order{
        account_id: account.id,
        customer_id: customer.id,
        status: "opened"
      })
      target_oli1 = Repo.insert!(%OrderLineItem{
        account_id: account.id,
        order_id: target_order.id,
        product_id: product.id,
        name: Faker.String.base64(5),
        charge_quantity: 1,
        sub_total_cents: 500,
        grand_total_cents: 500,
        authorization_total_cents: 500,
        auto_fulfill: true
      })
      target_oli2 = Repo.insert!(%OrderLineItem{
        account_id: account.id,
        order_id: target_order.id,
        parent_id: target_oli1.id,
        name: Faker.String.base64(5),
        charge_quantity: 1,
        sub_total_cents: 500,
        grand_total_cents: 500,
        authorization_total_cents: 500,
        auto_fulfill: true
      })

      CrmServiceMock
      |> expect(:get_customer, fn(_, _) ->
          customer
         end)

      CatalogueServiceMock
      |> expect(:get_product, fn(_, _) ->
          product
         end)

      preloads_path = [root_line_items: [:children, :product], customer: :point_account]
      preloads = %{ path: preloads_path }

      orders = Service.list_order(%{ account: account, preloads: preloads })
      assert length(orders) == 1

      order = Enum.at(orders, 0)

      assert order.id == target_order.id
      assert length(order.root_line_items) == 1

      oli1 = Enum.at(order.root_line_items, 0)
      assert oli1.id == target_oli1.id
      assert oli1.product.id == product.id

      oli2 = Enum.at(oli1.children, 0)
      assert oli2.id == target_oli2.id

      assert order.customer.id == customer.id
    end
  end

  describe "count_order/2" do
    test "order for different account is not returned" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      Repo.insert!(%Order{ account_id: account.id, status: "opened" })
      Repo.insert!(%Order{ account_id: account.id, status: "opened" })
      Repo.insert!(%Order{ account_id: other_account.id, status: "opened" })

      assert Service.count_order(%{ account: account }) == 2
    end

    test "only order matching filter is counted" do
      account = Repo.insert!(%Account{})
      Repo.insert!(%Account{})
      Repo.insert!(%Order{ account_id: account.id, status: "cart" })
      Repo.insert!(%Order{ account_id: account.id, status: "cart" })
      Repo.insert!(%Order{ account_id: account.id, status: "opened" })

      assert Service.count_order(%{ filter: %{ status: "opened" } }, %{ account: account }) == 1
    end
  end

  describe "create_order/2" do
    test "when given valid fields" do
      account = Repo.insert!(%Account{})
      {:ok, order} = Service.create_order(%{}, %{ account: account })

      assert order
    end
  end

  describe "get_order/2" do
    test "when given id" do
      account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: account.id
      })

      assert Service.get_order(%{ id: order.id }, %{ account: account })
    end

    test "when given id belongs to a different account" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: other_account.id
      })

      refute Service.get_order(%{ id: order.id }, %{ account: account })
    end

    test "when give id does not exist" do
      account = Repo.insert!(%Account{})

      refute Service.get_order(%{ id: Ecto.UUID.generate() }, %{ account: account })
    end
  end

  describe "update_order/2" do
    test "when given nil for order" do
      {:error, error} = Service.update_order(nil, %{}, %{})
      assert error == :not_found
    end

    test "when given id does not exist" do
      account = Repo.insert!(%Account{})

      {:error, error} = Service.update_order(Ecto.UUID.generate(), %{}, %{ account: account })
      assert error == :not_found
    end

    test "when given id belongs to a different account" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: other_account.id
      })

      {:error, error} =Service.update_order(order.id, %{}, %{ account: account })
      assert error == :not_found
    end

    test "when given valid id and invalid fields" do
      account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: account.id
      })

      {:error, changeset} = Service.update_order(order.id, %{ "status" => "regsitered" }, %{ account: account })
      assert length(changeset.errors) > 0
    end

    test "when given valid id and valid fields" do
      account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: account.id
      })

      fields = %{
        "name" => Faker.Name.name(),
        "email" => Faker.Internet.email(),
        "fulfillment_method" => "pickup"
      }

      {:ok, order} = Service.update_order(order.id, fields, %{ account: account })
      assert order
    end

    test "when given order and invalid fields" do
      account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: account.id
      })

      {:error, changeset} = Service.update_order(order, %{ "status" => "regsitered" }, %{ account: account })
      assert length(changeset.errors) > 0
    end

    test "when given order and valid fields" do
      account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: account.id
      })

      fields = %{
        "name" => Faker.Name.name(),
        "email" => Faker.Internet.email(),
        "fulfillment_method" => "pickup"
      }

      {:ok, order} = Service.update_order(order, fields, %{ account: account })
      assert order
    end
  end

  describe "delete_order/2" do
    test "when given order has existing payment" do
      account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: account.id
      })

      BalanceServiceMock
      |> expect(:count_payment, fn(_, _) -> 1 end)

      {:error, changeset} = Service.delete_order(order, %{ account: account })
      assert length(changeset.errors) == 1
    end

    test "when given valid order" do
      account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: account.id
      })

      BalanceServiceMock
      |> expect(:count_payment, fn(_, _) -> 0 end)

      {:ok, order} = Service.delete_order(order, %{ account: account })
      assert order
      refute Repo.get(Order, order.id)
    end
  end

  describe "create_order_line_item/2" do
    test "when given invalid fields" do
      account = Repo.insert!(%Account{})

      {:error, changeset} = Service.create_order_line_item(%{}, %{ account: account })
      assert length(changeset.errors) > 0
    end

    test "when given valid fields" do
      account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: account.id
      })

      BalanceServiceMock
      |> expect(:list_payment, fn(_, _) -> [] end)

      fields = %{
        "order_id" => order.id,
        "name" => Faker.Commerce.product_name(),
        "sub_total_cents" => 0
      }

      {:ok, oli} = Service.create_order_line_item(fields, %{ account: account })
      assert oli
    end
  end

  describe "update_order_line_item/3" do
    test "when given nil for oli" do
      {:error, error} = Service.update_order(nil, %{}, %{})

      assert error == :not_found
    end

    test "when given id belongs to a different account" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: other_account.id
      })

      {:error, error} = Service.update_order(order.id, %{}, %{ account: account })
      assert error == :not_found
    end

    test "when given valid id and invalid fields" do
      account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: account.id
      })
      order_line_item = Repo.insert!(%OrderLineItem{
        account_id: account.id,
        order_id: order.id,
        name: Faker.Commerce.product_name(),
        charge_quantity: 1,
        sub_total_cents: 500,
        grand_total_cents: 500,
        authorization_total_cents: 500,
        auto_fulfill: false
      })

      fields = %{
        "name" => nil
      }

      {:error, changeset} = Service.update_order_line_item(order_line_item.id, fields, %{ account: account })
      assert changeset.valid? == false
      assert length(changeset.errors) > 0
    end

    test "when given valid id and valid fields" do
      account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: account.id
      })
      oli = Repo.insert!(%OrderLineItem{
        account_id: account.id,
        order_id: order.id,
        name: Faker.Commerce.product_name(),
        charge_quantity: 1,
        sub_total_cents: 500,
        grand_total_cents: 500,
        authorization_total_cents: 500,
        auto_fulfill: false
      })

      BalanceServiceMock
      |> expect(:list_payment, fn(_, _) -> [] end)

      new_name = Faker.Commerce.product_name()
      fields = %{
        "name" => new_name
      }

      {:ok, oli} = Service.update_order_line_item(oli.id, fields, %{ account: account })
      assert oli.name == new_name
    end
  end

  describe "delete_order_line_item/2" do
    test "when given nil for oli" do
      {:error, error} = Service.delete_order_line_item(nil, %{})
      assert error == :not_found
    end

    test "when given valid id" do
      account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: account.id
      })
      oli = Repo.insert!(%OrderLineItem{
        account_id: account.id,
        order_id: order.id,
        name: Faker.Commerce.product_name(),
        charge_quantity: 1,
        sub_total_cents: 500,
        grand_total_cents: 500,
        authorization_total_cents: 500,
        auto_fulfill: false
      })

      BalanceServiceMock
      |> expect(:list_payment, fn(_, _) -> [] end)

      {:ok, oli} = Service.delete_order_line_item(oli.id, %{ account: account })
      refute Repo.get(OrderLineItem, oli.id)
    end
  end

  describe "list_unlock/2" do
    test "unlock for different account is not returned" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      customer = Repo.insert!(%Customer{
        account_id: other_account.id,
        name: Faker.Name.name()
      })
      unlockable = Repo.insert!(%Unlockable{
        account_id: other_account.id,
        name: Faker.Commerce.product_name()
      })
      Repo.insert!(%Unlock{
        account_id: other_account.id,
        customer_id: customer.id,
        unlockable_id: unlockable.id
      })

      unlocks = Service.list_unlock(%{ customer_id: customer.id }, %{ account: account })
      assert length(unlocks) == 0
    end

    test "valid request" do
      account = Repo.insert!(%Account{})
      customer = Repo.insert!(%Customer{
        account_id: account.id,
        name: Faker.Name.name()
      })
      unlockable = Repo.insert!(%Unlockable{
        account_id: account.id,
        name: Faker.Commerce.product_name()
      })
      Repo.insert!(%Unlock{
        account_id: account.id,
        customer_id: customer.id,
        unlockable_id: unlockable.id
      })

      unlocks = Service.list_unlock(%{ customer_id: customer.id }, %{ account: account })
      assert length(unlocks) == 1
    end
  end

  describe "count_unlock/2" do
    test "valid request" do
      account = Repo.insert!(%Account{})
      customer = Repo.insert!(%Customer{
        account_id: account.id,
        name: Faker.Name.name()
      })
      unlockable = Repo.insert!(%Unlockable{
        account_id: account.id,
        name: Faker.Commerce.product_name()
      })
      Repo.insert!(%Unlock{
        account_id: account.id,
        customer_id: customer.id,
        unlockable_id: unlockable.id
      })

      count = Service.count_unlock(%{ customer_id: customer.id }, %{ account: account })
      assert count == 1
    end
  end

  describe "create_unlock/2" do
    test "when given invalid fields" do
      account = Repo.insert!(%Account{})

      {:error, changeset} = Service.create_unlock(%{}, %{ account: account })
      assert changeset.valid? == false
      assert length(changeset.errors) > 0
    end

    test "when given valid fields" do
      account = Repo.insert!(%Account{})
      customer = Repo.insert!(%Customer{
        account_id: account.id,
        name: Faker.Name.name()
      })
      unlockable = Repo.insert!(%Unlockable{
        account_id: account.id,
        name: Faker.Commerce.product_name()
      })

      fields = %{
        "customer_id" => customer.id,
        "unlockable_id" => unlockable.id
      }

      {:ok, order} = Service.create_order(fields, %{ account: account })

      assert order
    end
  end

  describe "get_unlock/2" do
    test "when given invalid fields" do
      account = Repo.insert!(%Account{})

      refute Service.get_unlock(%{ customer_id: Ecto.UUID.generate() }, %{ account: account })
    end

    test "when given valid fields" do
      account = Repo.insert!(%Account{})
      customer = Repo.insert!(%Customer{
        account_id: account.id,
        name: Faker.Name.name()
      })
      unlockable = Repo.insert!(%Unlockable{
        account_id: account.id,
        name: Faker.Commerce.product_name()
      })
      Repo.insert!(%Unlock{
        account_id: account.id,
        customer_id: customer.id,
        unlockable_id: unlockable.id
      })

      fields = %{
        customer_id: customer.id,
        unlockable_id: unlockable.id
      }

      unlock = Service.get_unlock(fields, %{ account: account })
      assert unlock
    end
  end

  describe "delete_unlock/2" do
    test "when given unlock is nil" do
      {:error, error} = Service.delete_unlock(nil, %{})
      assert error == :not_found
    end

    test "when given unlock is valid" do
      account = Repo.insert!(%Account{})
      customer = Repo.insert!(%Customer{
        account_id: account.id,
        name: Faker.Name.name()
      })
      unlockable = Repo.insert!(%Unlockable{
        account_id: account.id,
        name: Faker.Commerce.product_name()
      })
      unlock = Repo.insert!(%Unlock{
        account_id: account.id,
        customer_id: customer.id,
        unlockable_id: unlockable.id
      })

      {:ok, _} = Service.delete_unlock(unlock, %{ account: account })
    end

    test "when given id is valid" do
      account = Repo.insert!(%Account{})
      customer = Repo.insert!(%Customer{
        account_id: account.id,
        name: Faker.Name.name()
      })
      unlockable = Repo.insert!(%Unlockable{
        account_id: account.id,
        name: Faker.Commerce.product_name()
      })
      unlock = Repo.insert!(%Unlock{
        account_id: account.id,
        customer_id: customer.id,
        unlockable_id: unlockable.id
      })

      {:ok, _} = Service.delete_unlock(unlock.id, %{ account: account })
    end
  end
end
