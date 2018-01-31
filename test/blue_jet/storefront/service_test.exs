defmodule BlueJet.Storefront.ServiceTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity.Account
  alias BlueJet.Crm.Customer
  alias BlueJet.Catalogue.Product

  alias BlueJet.Storefront.{CrmServiceMock, CatalogueServiceMock}
  alias BlueJet.Storefront.Service
  alias BlueJet.Storefront.{Order, OrderLineItem}

  test "play" do
    # IO.inspect BlueJet.Plugs.Include.to_preloads("root_line_items.children,root_line_items.product,customer.point_account")
  end

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
      other_account = Repo.insert!(%Account{})
      Repo.insert!(%Order{ account_id: account.id, status: "cart" })
      Repo.insert!(%Order{ account_id: account.id, status: "cart" })
      Repo.insert!(%Order{ account_id: account.id, status: "opened" })

      assert Service.count_order(%{ filter: %{ status: "opened" } }, %{ account: account }) == 1
    end
  end
end
