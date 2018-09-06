defmodule BlueJet.StorefrontTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity.{Account, User}

  alias BlueJet.Storefront
  alias BlueJet.Storefront.{CrmServiceMock}
  alias BlueJet.Storefront.{ServiceMock, Order, OrderLineItem}

  #
  # MARK: Order
  #
  describe "list_order/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: nil,
        role: "guest"
      }

      {:error, :access_denied} = Storefront.list_order(request)
    end

    test "when role is customer" do
      account = %Account{}
      user = %User{ id: Ecto.UUID.generate() }
      customer = %{ id: Ecto.UUID.generate() }
      request = %ContextRequest{
        account: account,
        user: user,
        role: "customer"
      }

      CrmServiceMock
      |> expect(:get_customer, fn(identifiers, _) ->
          assert identifiers.user_id == user.id

          customer
         end)

      ServiceMock
      |> expect(:list_order, fn(fields, opts) ->
          assert fields.filter.customer_id == customer.id
          assert fields.filter.status == ["opened", "closed"]
          assert opts.account == account

          [%Order{}]
         end)
      |> expect(:count_order, fn(fields, opts) ->
          assert fields.filter.customer_id == customer.id
          assert fields.filter.status == ["opened", "closed"]

          assert opts.account == account

          1
         end)
      |> expect(:count_order, fn(fields, opts) ->
          assert fields.filter.customer_id == customer.id
          assert fields.filter.status == ["opened", "closed"]
          assert opts.account == account

          1
         end)


      {:ok, _} = Storefront.list_order(request)
    end

    test "when role is administrator" do
      account = %Account{}
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator"
      }

      ServiceMock
      |> expect(:list_order, fn(_, opts) ->
          assert opts.account == account

          [%Order{}]
         end)
      |> expect(:count_order, fn(_, opts) ->
          assert opts.account == account

          1
         end)
      |> expect(:count_order, fn(_, opts) ->
          assert opts.account == account

          1
         end)

      {:ok, _} = Storefront.list_order(request)
    end
  end

  describe "create_order/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: nil,
        user: nil,
        role: "anonymous"
      }

      {:error, :access_denied} = Storefront.create_order(request)
    end

    test "when role is customer" do
      account = %Account{}
      user = %User{ id: Ecto.UUID.generate() }
      customer = %{ id: Ecto.UUID.generate() }
      request = %ContextRequest{
        account: account,
        user: user,
        role: "customer"
      }

      CrmServiceMock
      |> expect(:get_customer, fn(identifiers, _) ->
          assert identifiers.user_id == user.id

          customer
         end)

      ServiceMock
      |> expect(:create_order, fn(fields, opts) ->
          assert fields == Map.merge(request.fields, %{ customer_id: customer.id })
          assert opts.account == account

          {:ok, %Order{}}
         end)

      {:ok, _} = Storefront.create_order(request)
    end

    test "when role is administrator" do
      account = %Account{}
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator",
        fields: %{
          "name" => Faker.Name.name()
        }
      }

      ServiceMock
      |> expect(:create_order, fn(fields, opts) ->
          assert fields == request.fields
          assert opts.account == account

          {:ok, %Order{}}
         end)

      {:ok, _} = Storefront.create_order(request)
    end
  end

  describe "get_order/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: nil,
        user: nil,
        role: "anonymous"
      }

      {:error, :access_denied} = Storefront.get_order(request)
    end

    test "when role is guest" do
      order = %Order{ id: Ecto.UUID.generate() }

      request = %ContextRequest{
        account: %Account{},
        user: nil,
        role: "guest",
        params: %{ "id" => order.id }
      }

      ServiceMock
      |> expect(:get_order, fn(identifiers, _) ->
          assert identifiers.id == order.id
          assert identifiers.customer_id == nil
          assert identifiers.status == "cart"

          {:ok, order}
         end)

      {:ok, _} = Storefront.get_order(request)
    end

    test "when role is customer" do
      order = %Order{ id: Ecto.UUID.generate() }
      user = %User{ id: Ecto.UUID.generate() }
      customer = %{ id: Ecto.UUID.generate() }
      request = %ContextRequest{
        account: %Account{},
        user: user,
        role: "customer",
        params: %{ "id" => order.id }
      }

      CrmServiceMock
      |> expect(:get_customer, fn(identifiers, _) ->
          assert identifiers.user_id == user.id

          customer
         end)

      ServiceMock
      |> expect(:get_order, fn(identifiers, _) ->
          assert identifiers.id == order.id
          assert identifiers.customer_id == customer.id

          {:ok, order}
         end)

      {:ok, _} = Storefront.get_order(request)
    end

    test "when role is administrator" do
      order = %Order{ id: Ecto.UUID.generate() }

      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "administrator",
        params: %{ "id" => order.id }
      }

      ServiceMock
      |> expect(:get_order, fn(identifiers, _) ->
          assert identifiers.id == order.id

          {:ok, %Order{}}
         end)

      {:ok, _} = Storefront.get_order(request)
    end
  end

  describe "update_order/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: nil,
        user: nil,
        role: "anonymous"
      }

      {:error, :access_denied} = Storefront.update_order(request)
    end

    test "when role is guest" do
      account = %Account{}
      user = %User{ id: Ecto.UUID.generate() }
      request = %ContextRequest{
        account: account,
        user: user,
        role: "guest",
        params: %{ "id" => Ecto.UUID.generate() }
      }

      ServiceMock
      |> expect(:update_order, fn(identifiers, fields, opts) ->
          assert identifiers.id == request.params["id"]
          assert identifiers.customer_id == nil
          assert identifiers.status == "cart"
          assert fields == request.fields
          assert opts.account == account

          {:ok, %Order{}}
         end)

      {:ok, _} = Storefront.update_order(request)
    end

    test "when role is customer" do
      account = %Account{}
      user = %User{ id: Ecto.UUID.generate() }
      customer = %{ id: Ecto.UUID.generate() }
      request = %ContextRequest{
        account: account,
        user: user,
        role: "customer",
        params: %{ "id" => Ecto.UUID.generate() }
      }

      CrmServiceMock
      |> expect(:get_customer, fn(identifiers, _) ->
          assert identifiers.user_id == user.id

          customer
         end)

      ServiceMock
      |> expect(:update_order, fn(identifiers, fields, opts) ->
          assert identifiers.id == request.params["id"]
          assert identifiers.status == "cart"
          assert identifiers.customer_id == customer.id
          assert fields == request.fields
          assert opts.account == account

          {:ok, %Order{}}
         end)

      {:ok, _} = Storefront.update_order(request)
    end

    test "when role is administrator" do
      account = %Account{}
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator",
        params: %{ "id" => Ecto.UUID.generate() },
        fields: %{
          "name" => Faker.Name.name()
        }
      }

      ServiceMock
      |> expect(:update_order, fn(identifiers, fields, opts) ->
          assert identifiers.id == request.params["id"]
          assert fields == request.fields
          assert opts.account == account

          {:ok, %Order{}}
         end)

      {:ok, _} = Storefront.update_order(request)
    end
  end

  describe "delete_order/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: nil,
        user: nil,
        role: "anonymous"
      }

      {:error, :access_denied} = Storefront.delete_order(request)
    end

    test "when role is guest" do
      account = %Account{}
      request = %ContextRequest{
        account: account,
        user: nil,
        role: "guest",
        params: %{ "id" => Ecto.UUID.generate() }
      }

      ServiceMock
      |> expect(:delete_order, fn(identifiers, opts) ->
          assert identifiers.id == request.params["id"]
          assert identifiers.customer_id == nil
          assert identifiers.status == "cart"
          assert opts.account == account

          {:ok, %Order{}}
         end)

      {:ok, _} = Storefront.delete_order(request)
    end

    test "when role is customer" do
      account = %Account{}
      user = %User{ id: Ecto.UUID.generate() }
      customer = %{ id: Ecto.UUID.generate() }
      request = %ContextRequest{
        account: account,
        user: user,
        role: "customer",
        params: %{ "id" => Ecto.UUID.generate() }
      }

      CrmServiceMock
      |> expect(:get_customer, fn(identifiers, _) ->
          assert identifiers.user_id == user.id

          customer
         end)

      ServiceMock
      |> expect(:delete_order, fn(identifiers, opts) ->
          assert identifiers.id == request.params["id"]
          assert identifiers.status == "cart"
          assert identifiers.customer_id == customer.id
          assert opts.account == account

          {:ok, %Order{}}
         end)

      {:ok, _} = Storefront.delete_order(request)
    end

    test "when role is administrator" do
      account = %Account{}
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator",
        params: %{ "id" => Ecto.UUID.generate() }
      }

      ServiceMock
      |> expect(:delete_order, fn(identifiers, opts) ->
          assert identifiers.id == request.params["id"]
          assert opts.account == account

          {:ok, %Order{}}
         end)

      {:ok, _} = Storefront.delete_order(request)
    end
  end

  #
  # MARK: Order Line Item
  #
  describe "create_order_line_item/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: nil,
        user: nil,
        role: "anonymous"
      }

      {:error, :access_denied} = Storefront.create_order_line_item(request)
    end

    test "when role is guest and the order is not in cart status or the customer_id does not match" do
      account = %Account{}
      order = %Order{ id: Ecto.UUID.generate() }
      request = %ContextRequest{
        account: account,
        user: nil,
        role: "guest",
        fields: %{
          "name" => Faker.Commerce.product_name(),
          "order_id" => order.id
        }
      }

      ServiceMock
      |> expect(:get_order, fn(identifiers, _) ->
          assert identifiers.id == order.id
          assert identifiers.status == "cart"
          assert identifiers.customer_id == nil

          nil
         end)

      {:error, :access_denied} = Storefront.create_order_line_item(request)
    end

    test "when role is customer and the order is not in cart status or does not belongs to the customer" do
      account = %Account{}
      user = %User{ id: Ecto.UUID.generate() }
      customer = %{ id: Ecto.UUID.generate() }
      order = %Order{ id: Ecto.UUID.generate() }
      request = %ContextRequest{
        account: account,
        user: user,
        role: "customer",
        fields: %{ "name" => Faker.Commerce.product_name(), "order_id" => order.id }
      }

      CrmServiceMock
      |> expect(:get_customer, fn(identifiers, _) ->
          assert identifiers.user_id == user.id

          customer
         end)

      ServiceMock
      |> expect(:get_order, fn(identifiers, _) ->
          assert identifiers.id == order.id
          assert identifiers.status == "cart"
          assert identifiers.customer_id == customer.id

          nil
         end)

      {:error, :access_denied} = Storefront.create_order_line_item(request)
    end

    test "when role is customer and given order is in cart status and belongs to the customer" do
      account = %Account{}
      user = %User{ id: Ecto.UUID.generate() }
      customer = %{ id: Ecto.UUID.generate() }
      order = %Order{ id: Ecto.UUID.generate() }
      request = %ContextRequest{
        account: account,
        user: user,
        role: "customer",
        fields: %{ "order_id" => order.id, "name" => Faker.Commerce.product_name() }
      }

      CrmServiceMock
      |> expect(:get_customer, fn(identifiers, _) ->
          assert identifiers.user_id == user.id

          customer
         end)

      ServiceMock
      |> expect(:get_order, fn(identifiers, _) ->
          assert identifiers.id == order.id
          assert identifiers.status == "cart"
          assert identifiers.customer_id == customer.id

          order
         end)

      ServiceMock
      |> expect(:create_order_line_item, fn(fields, opts) ->
          assert fields == request.fields
          assert opts.account == account

          {:ok, %OrderLineItem{}}
         end)

      {:ok, _} = Storefront.create_order_line_item(request)
    end

    test "when role is administrator" do
      account = %Account{}
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator",
        fields: %{
          "order_id" => Ecto.UUID.generate(),
          "name" => Faker.Commerce.product_name()
        }
      }

      ServiceMock
      |> expect(:create_order_line_item, fn(fields, opts) ->
          assert fields == request.fields
          assert opts.account == account

          {:ok, %OrderLineItem{}}
         end)

      {:ok, _} = Storefront.create_order_line_item(request)
    end
  end

  describe "update_order_line_item/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: nil,
        user: nil,
        role: "anonymous"
      }

      {:error, :access_denied} = Storefront.update_order_line_item(request)
    end

    test "when role is guest and the order is not in cart status or the customer_id does not match" do
      account = %Account{}
      order = %Order{ id: Ecto.UUID.generate() }
      request = %ContextRequest{
        account: account,
        user: nil,
        role: "guest",
        params: %{ "id" => Ecto.UUID.generate() },
        fields: %{
          "name" => Faker.Commerce.product_name()
        }
      }

      ServiceMock
      |> expect(:get_order_line_item, fn(identifiers, _) ->
          assert identifiers.id == request.params["id"]

          %OrderLineItem{ order_id: order.id }
         end)

      ServiceMock
      |> expect(:get_order, fn(identifiers, _) ->
          assert identifiers.id == order.id
          assert identifiers.status == "cart"
          assert identifiers.customer_id == nil

          nil
         end)

      {:error, :access_denied} = Storefront.update_order_line_item(request)
    end

    test "when role is customer and the order is not in cart status or does not belongs to the customer" do
      account = %Account{}
      user = %User{ id: Ecto.UUID.generate() }
      customer = %{ id: Ecto.UUID.generate() }
      order = %Order{ id: Ecto.UUID.generate() }
      request = %ContextRequest{
        account: account,
        user: user,
        role: "customer",
        params: %{ "id" => Ecto.UUID.generate() },
        fields: %{
          "name" => Faker.Commerce.product_name()
        }
      }

      CrmServiceMock
      |> expect(:get_customer, fn(identifiers, _) ->
          assert identifiers.user_id == user.id

          customer
         end)

      ServiceMock
      |> expect(:get_order_line_item, fn(identifiers, _) ->
          assert identifiers.id == request.params["id"]

          %OrderLineItem{ order_id: order.id }
         end)

      ServiceMock
      |> expect(:get_order, fn(identifiers, _) ->
          assert identifiers.id == order.id
          assert identifiers.status == "cart"
          assert identifiers.customer_id == customer.id

          nil
         end)

      {:error, :access_denied} = Storefront.update_order_line_item(request)
    end

    test "when role is customer and given order is in cart status and belongs to the customer" do
      account = %Account{}
      user = %User{ id: Ecto.UUID.generate() }
      customer = %{ id: Ecto.UUID.generate() }
      order = %Order{ id: Ecto.UUID.generate() }
      request = %ContextRequest{
        account: account,
        user: user,
        role: "customer",
        params: %{ "id" => Ecto.UUID.generate() },
        fields: %{
          "name" => Faker.Commerce.product_name()
        }
      }

      CrmServiceMock
      |> expect(:get_customer, fn(identifiers, _) ->
          assert identifiers.user_id == user.id

          customer
         end)

      ServiceMock
      |> expect(:get_order_line_item, fn(identifiers, _) ->
          assert identifiers.id == request.params["id"]

          %OrderLineItem{ order_id: order.id }
         end)

      ServiceMock
      |> expect(:get_order, fn(identifiers, _) ->
          assert identifiers.id == order.id
          assert identifiers.status == "cart"
          assert identifiers.customer_id == customer.id

          order
         end)

      ServiceMock
      |> expect(:update_order_line_item, fn(identifiers, fields, opts) ->
          assert identifiers.id == request.params["id"]
          assert fields == request.fields
          assert opts.account == account

          {:ok, %OrderLineItem{}}
         end)

      {:ok, _} = Storefront.update_order_line_item(request)
    end

    test "when role is administrator" do
      account = %Account{}
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator",
        params: %{ "id" => Ecto.UUID.generate() },
        fields: %{
          "name" => Faker.Commerce.product_name()
        }
      }

      ServiceMock
      |> expect(:update_order_line_item, fn(identifiers, fields, opts) ->
          assert identifiers.id == request.params["id"]
          assert fields == request.fields
          assert opts.account == account

          {:ok, %OrderLineItem{}}
         end)

      {:ok, _} = Storefront.update_order_line_item(request)
    end
  end

  describe "delete_order_line_item/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: nil,
        user: nil,
        role: "anonymous"
      }

      {:error, :access_denied} = Storefront.delete_order_line_item(request)
    end


    test "when role is guest and the order is not in cart status or the customer_id does not match" do
      account = %Account{}
      order = %Order{ id: Ecto.UUID.generate() }
      request = %ContextRequest{
        account: account,
        user: nil,
        role: "guest",
        params: %{ "id" => Ecto.UUID.generate() }
      }

      ServiceMock
      |> expect(:get_order_line_item, fn(identifiers, _) ->
          assert identifiers.id == request.params["id"]

          %OrderLineItem{ order_id: order.id }
         end)

      ServiceMock
      |> expect(:get_order, fn(identifiers, _) ->
          assert identifiers.id == order.id
          assert identifiers.status == "cart"
          assert identifiers.customer_id == nil

          nil
         end)

      {:error, :access_denied} = Storefront.delete_order_line_item(request)
    end

    test "when role is customer and the order is not in cart status or does not belongs to the customer" do
      account = %Account{}
      user = %User{ id: Ecto.UUID.generate() }
      customer = %{ id: Ecto.UUID.generate() }
      order = %Order{ id: Ecto.UUID.generate() }
      request = %ContextRequest{
        account: account,
        user: user,
        role: "customer",
        params: %{ "id" => Ecto.UUID.generate() }
      }

      CrmServiceMock
      |> expect(:get_customer, fn(identifiers, _) ->
          assert identifiers.user_id == user.id

          customer
         end)

      ServiceMock
      |> expect(:get_order_line_item, fn(identifiers, _) ->
          assert identifiers.id == request.params["id"]

          %OrderLineItem{ order_id: order.id }
         end)

      ServiceMock
      |> expect(:get_order, fn(identifiers, _) ->
          assert identifiers.id == order.id
          assert identifiers.status == "cart"
          assert identifiers.customer_id == customer.id

          nil
         end)

      {:error, :access_denied} = Storefront.delete_order_line_item(request)
    end

    test "when role is customer and given order is in cart status and belongs to the customer" do
      account = %Account{}
      user = %User{ id: Ecto.UUID.generate() }
      customer = %{ id: Ecto.UUID.generate() }
      order = %Order{ id: Ecto.UUID.generate() }
      request = %ContextRequest{
        account: account,
        user: user,
        role: "customer",
        params: %{ "id" => Ecto.UUID.generate() }
      }

      CrmServiceMock
      |> expect(:get_customer, fn(identifiers, _) ->
          assert identifiers.user_id == user.id

          customer
         end)

      ServiceMock
      |> expect(:get_order_line_item, fn(identifiers, _) ->
          assert identifiers.id == request.params["id"]

          %OrderLineItem{ order_id: order.id }
         end)

      ServiceMock
      |> expect(:get_order, fn(identifiers, _) ->
          assert identifiers.id == order.id
          assert identifiers.status == "cart"
          assert identifiers.customer_id == customer.id

          order
         end)

      ServiceMock
      |> expect(:delete_order_line_item, fn(identifiers, opts) ->
          assert identifiers.id == request.params["id"]
          assert opts.account == account

          {:ok, %OrderLineItem{}}
         end)

      {:ok, _} = Storefront.delete_order_line_item(request)
    end

    test "when role is administrator" do
      account = %Account{}
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator",
        params: %{ "id" => Ecto.UUID.generate() }
      }

      ServiceMock
      |> expect(:delete_order_line_item, fn(identifiers, opts) ->
          assert identifiers.id == request.params["id"]
          assert opts.account == account

          {:ok, %OrderLineItem{}}
         end)

      {:ok, _} = Storefront.delete_order_line_item(request)
    end
  end
end
