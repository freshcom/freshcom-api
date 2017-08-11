defmodule BlueJet.OrderLineItemTest do
  use BlueJet.DataCase

  alias BlueJet.Identity.Account
  alias BlueJet.Storefront.Order
  alias BlueJet.Storefront.OrderLineItem
  alias BlueJet.Storefront.ProductItem
  alias BlueJet.Storefront.Product

  @valid_params %{
    account_id: Ecto.UUID.generate(),
    status: "active",
    name: "Apple",
    item_mode: "all",
    custom_data: %{
      kind: "Gala"
    }
  }
  @invalid_params %{}

  describe "schema" do
    test "defaults" do
      struct = %Product{}

      assert struct.item_mode == "any"
      assert struct.custom_data == %{}
      assert struct.translations == %{}
    end
  end

  describe "balance!/1" do
    test "with custom OrderLineItem" do
      account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: account.id
      })
      item = Repo.insert!(%OrderLineItem{
        account_id: account.id,
        is_leaf: true,
        parent_id: nil,
        order_id: order.id
      })

      OrderLineItem.balance!(item)
      children = Ecto.assoc(item, :children) |> Repo.all()

      assert length(children) == 0
    end

    @tag :focus
    test "with OrderLineItem with ProductItem" do
      account = Repo.insert!(%Account{})
      product = Repo.insert!(%Product{
        status: "active",
        name: "Apple",
        account_id: account.id
      })
      product_item = Repo.insert!(%ProductItem{
        status: "active",
        account_id: account.id,
        product_id: product.id
      })
      order = Repo.insert!(%Order{
        account_id: account.id
      })
      order_line_item = Repo.insert!(%OrderLineItem{
        account_id: account.id,
        is_leaf: false,
        parent_id: nil,
        order_id: order.id,
        order_quantity: 3,
        product_item_id: product_item.id
      })

      children = order_line_item |> OrderLineItem.balance!() |> Ecto.assoc(:children) |> Repo.all()

      assert length(children) == 3

      children =
        %{ order_line_item | order_quantity: 5 }
        |> OrderLineItem.balance!()
        |> Ecto.assoc(:children)
        |> Repo.all()

      assert length(children) == 5

      children =
        %{ order_line_item | order_quantity: 2 }
        |> OrderLineItem.balance!()
        |> Ecto.assoc(:children)
        |> Repo.all()

      assert length(children) == 2
    end
  end
end
