defmodule BlueJet.FulfillmentTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity.{Account, User}

  alias BlueJet.Fulfillment
  alias BlueJet.Fulfillment.{CrmServiceMock}
  alias BlueJet.Fulfillment.{ServiceMock, FulfillmentPackage, FulfillmentItem, ReturnPackage, ReturnItem, Unlock}

  #
  # MARK: Fulfillment Package
  #
  describe "list_fulfillment_package/1" do
    test "when role is not authorized" do
      request = %AccessRequest{
        account: %Account{},
        user: %User{},
        role: "guest"
      }

      {:error, :access_denied} = Fulfillment.list_fulfillment_package(request)
    end

    test "when role is support specialist and no order ID or customer ID is provided" do
      request = %AccessRequest{
        account: %Account{},
        user: %User{},
        role: "support_specialist"
      }

      {:error, :access_denied} = Fulfillment.list_fulfillment_package(request)
    end

    test "when role is support specialist and order ID is provided" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        user: %User{},
        role: "support_specialist",
        filter: %{ order_id: Ecto.UUID.generate() }
      }

      ServiceMock
      |> expect(:list_fulfillment_package, fn(fields, opts) ->
          assert fields[:filter][:order_id] == request.filter[:order_id]
          assert opts[:account] == account

          [%FulfillmentPackage{}]
         end)
      |> expect(:count_fulfillment_package, fn(fields, opts) ->
          assert fields[:filter][:order_id] == request.filter[:order_id]
          assert opts[:account] == account

          1
         end)
      |> expect(:count_fulfillment_package, fn(fields, opts) ->
          assert fields[:filter][:order_id] == request.filter[:order_id]
          assert opts[:account] == account

          1
         end)


      {:ok, _} = Fulfillment.list_fulfillment_package(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        user: %User{},
        role: "administrator"
      }

      ServiceMock
      |> expect(:list_fulfillment_package, fn(_, opts) ->
          assert opts[:account] == account

          [%FulfillmentPackage{}]
         end)
      |> expect(:count_fulfillment_package, fn(_, opts) ->
          assert opts[:account] == account

          1
         end)
      |> expect(:count_fulfillment_package, fn(_, opts) ->
          assert opts[:account] == account

          1
         end)

      {:ok, _} = Fulfillment.list_fulfillment_package(request)
    end
  end

  describe "get_fulfillment_package/1" do
    test "when role is not authorized" do
      request = %AccessRequest{
        account: %Account{},
        user: %User{},
        role: "guest"
      }

      {:error, :access_denied} = Fulfillment.get_fulfillment_package(request)
    end

    test "when request is valid" do
      fulfillment_package = %FulfillmentPackage{ id: Ecto.UUID.generate() }

      request = %AccessRequest{
        account: %Account{},
        user: %User{},
        role: "administrator",
        params: %{ "id" => fulfillment_package.id }
      }

      ServiceMock
      |> expect(:get_fulfillment_package, fn(identifiers, _) ->
          assert identifiers[:id] == fulfillment_package.id

          {:ok, %FulfillmentPackage{}}
         end)

      {:ok, _} = Fulfillment.get_fulfillment_package(request)
    end
  end

  describe "delete_fulfillment_package/1" do
    test "when role is not authorized" do
      request = %AccessRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Fulfillment.delete_fulfillment_package(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        user: %User{},
        role: "administrator",
        params: %{ "id" => Ecto.UUID.generate() }
      }

      ServiceMock
      |> expect(:delete_fulfillment_package, fn(id, opts) ->
          assert id == request.params["id"]
          assert opts[:account] == account

          {:ok, %FulfillmentPackage{}}
         end)

      {:ok, _} = Fulfillment.delete_fulfillment_package(request)
    end
  end

  #
  # MARK: Fulfillment Item
  #
  describe "list_fulfillment_item/1" do
    test "when role is not authorized" do
      request = %AccessRequest{
        account: %Account{},
        user: %User{},
        role: "guest"
      }

      {:error, :access_denied} = Fulfillment.list_fulfillment_item(request)
    end

    test "when role is customer but package ID is not provided" do
      request = %AccessRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Fulfillment.list_fulfillment_item(request)
    end

    test "when role is customer and package ID is provided" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        user: %User{},
        role: "customer",
        params: %{ "package_id" => Ecto.UUID.generate() }
      }

      ServiceMock
      |> expect(:list_fulfillment_item, fn(fields, opts) ->
          assert fields[:filter][:package_id] == request.params["package_id"]
          assert opts[:account] == account

          [%FulfillmentItem{}]
         end)
      |> expect(:count_fulfillment_item, fn(fields, opts) ->
          assert fields[:filter][:package_id] == request.params["package_id"]
          assert opts[:account] == account

          1
         end)
      |> expect(:count_fulfillment_item, fn(fields, opts) ->
          assert fields[:filter][:package_id] == request.params["package_id"]
          assert opts[:account] == account

          1
         end)


      {:ok, _} = Fulfillment.list_fulfillment_item(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        user: %User{},
        role: "administrator"
      }

      ServiceMock
      |> expect(:list_fulfillment_item, fn(_, opts) ->
          assert opts[:account] == account

          [%FulfillmentItem{}]
         end)
      |> expect(:count_fulfillment_item, fn(_, opts) ->
          assert opts[:account] == account

          1
         end)
      |> expect(:count_fulfillment_item, fn(_, opts) ->
          assert opts[:account] == account

          1
         end)

      {:ok, _} = Fulfillment.list_fulfillment_item(request)
    end
  end

  describe "create_fulfillment_item/1" do
    test "when role is not authorized" do
      request = %AccessRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Fulfillment.create_fulfillment_item(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        user: %User{},
        role: "administrator",
        fields: %{
          "name" => Faker.Commerce.product_name()
        }
      }

      ServiceMock
      |> expect(:create_fulfillment_item, fn(fields, opts) ->
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, %FulfillmentItem{}}
         end)

      {:ok, _} = Fulfillment.create_fulfillment_item(request)
    end
  end

  describe "update_fulfillment_item/1" do
    test "when role is not authorized" do
      request = %AccessRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Fulfillment.update_fulfillment_item(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        user: %User{},
        role: "administrator",
        params: %{ "id" => Ecto.UUID.generate() },
        fields: %{
          "name" => Faker.Commerce.product_name()
        }
      }

      ServiceMock
      |> expect(:update_fulfillment_item, fn(id, fields, opts) ->
          assert id == request.params["id"]
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, %FulfillmentItem{}}
         end)

      {:ok, _} = Fulfillment.update_fulfillment_item(request)
    end
  end

  #
  # MARK: Return Package
  #
  describe "list_return_package/1" do
    test "when role is not authorized" do
      request = %AccessRequest{
        account: %Account{},
        user: %User{},
        role: "guest"
      }

      {:error, :access_denied} = Fulfillment.list_return_package(request)
    end

    test "when role is support specialist and no order ID or customer ID is provided" do
      request = %AccessRequest{
        account: %Account{},
        user: %User{},
        role: "support_specialist"
      }

      {:error, :access_denied} = Fulfillment.list_return_package(request)
    end

    test "when role is support specialist and order ID is provided" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        user: %User{},
        role: "support_specialist",
        filter: %{ order_id: Ecto.UUID.generate() }
      }

      ServiceMock
      |> expect(:list_return_package, fn(fields, opts) ->
          assert fields[:filter][:order_id] == request.filter[:order_id]
          assert opts[:account] == account

          [%ReturnPackage{}]
         end)
      |> expect(:count_return_package, fn(fields, opts) ->
          assert fields[:filter][:order_id] == request.filter[:order_id]
          assert opts[:account] == account

          1
         end)
      |> expect(:count_return_package, fn(fields, opts) ->
          assert fields[:filter][:order_id] == request.filter[:order_id]
          assert opts[:account] == account

          1
         end)


      {:ok, _} = Fulfillment.list_return_package(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        user: %User{},
        role: "administrator"
      }

      ServiceMock
      |> expect(:list_return_package, fn(_, opts) ->
          assert opts[:account] == account

          [%ReturnPackage{}]
         end)
      |> expect(:count_return_package, fn(_, opts) ->
          assert opts[:account] == account

          1
         end)
      |> expect(:count_return_package, fn(_, opts) ->
          assert opts[:account] == account

          1
         end)

      {:ok, _} = Fulfillment.list_return_package(request)
    end
  end

  #
  # MARK: Return Item
  #
  describe "create_return_item/1" do
    test "when role is not authorized" do
      request = %AccessRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Fulfillment.create_return_item(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        user: %User{},
        role: "administrator",
        fields: %{
          "name" => Faker.Commerce.product_name()
        }
      }

      ServiceMock
      |> expect(:create_return_item, fn(fields, opts) ->
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, %ReturnItem{}}
         end)

      {:ok, _} = Fulfillment.create_return_item(request)
    end
  end

  #
  # MARK: Unlock
  #
  describe "list_unlock/1" do
    test "when role is not authorized" do
      request = %AccessRequest{
        account: %Account{},
        user: %User{},
        role: "guest"
      }

      {:error, :access_denied} = Fulfillment.list_unlock(request)
    end

    test "when role is customer" do
      account = %Account{}
      user = %User{ id: Ecto.UUID.generate() }
      customer = %{ id: Ecto.UUID.generate() }
      request = %AccessRequest{
        account: account,
        user: user,
        role: "customer"
      }

      CrmServiceMock
      |> expect(:get_customer, fn(identifiers, _) ->
          assert identifiers[:user_id] == user.id

          customer
         end)

      ServiceMock
      |> expect(:list_unlock, fn(fields, opts) ->
          assert fields[:filter][:customer_id] == customer.id
          assert opts[:account] == account

          [%Unlock{}]
         end)
      |> expect(:count_unlock, fn(fields, opts) ->
          assert fields[:filter][:customer_id] == customer.id
          assert opts[:account] == account

          1
         end)
      |> expect(:count_unlock, fn(fields, opts) ->
          assert fields[:filter][:customer_id] == customer.id
          assert opts[:account] == account

          1
         end)


      {:ok, _} = Fulfillment.list_unlock(request)
    end

    test "when role is support specialist and customer ID is not provided" do
      request = %AccessRequest{
        account: %Account{},
        user: %User{},
        role: "support_specialist"
      }

      {:error, :access_denied} = Fulfillment.list_unlock(request)
    end

    test "when role is support specialist and customer ID is provided" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        user: %User{},
        role: "support_specialist",
        filter: %{ customer_id: Ecto.UUID.generate() }
      }

      ServiceMock
      |> expect(:list_unlock, fn(fields, opts) ->
          assert fields[:filter][:customer_id] == request.filter[:customer_id]
          assert opts[:account] == account

          [%Unlock{}]
         end)
      |> expect(:count_unlock, fn(fields, opts) ->
          assert fields[:filter][:customer_id] == request.filter[:customer_id]
          assert opts[:account] == account

          1
         end)
      |> expect(:count_unlock, fn(fields, opts) ->
          assert fields[:filter][:customer_id] == request.filter[:customer_id]
          assert opts[:account] == account

          1
         end)


      {:ok, _} = Fulfillment.list_unlock(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        user: %User{},
        role: "administrator"
      }

      ServiceMock
      |> expect(:list_unlock, fn(_, opts) ->
          assert opts[:account] == account

          [%Unlock{}]
         end)
      |> expect(:count_unlock, fn(_, opts) ->
          assert opts[:account] == account

          1
         end)
      |> expect(:count_unlock, fn(_, opts) ->
          assert opts[:account] == account

          1
         end)

      {:ok, _} = Fulfillment.list_unlock(request)
    end
  end

  describe "create_unlock/1" do
    test "when role is not authorized" do
      request = %AccessRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Fulfillment.create_unlock(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        user: %User{},
        role: "administrator",
        fields: %{
          "customer_id" => Ecto.UUID.generate(),
          "unlock_id" => Ecto.UUID.generate()
        }
      }

      ServiceMock
      |> expect(:create_unlock, fn(fields, opts) ->
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, %Unlock{}}
         end)

      {:ok, _} = Fulfillment.create_unlock(request)
    end
  end

  describe "get_unlock/1" do
    test "when role is not authorized" do
      request = %AccessRequest{
        account: %Account{},
        user: %User{},
        role: "guest"
      }

      {:error, :access_denied} = Fulfillment.get_unlock(request)
    end

    test "when request is valid" do
      request = %AccessRequest{
        account: %Account{},
        user: %User{},
        role: "administrator",
        params: %{ "id" => Ecto.UUID.generate() }
      }

      ServiceMock
      |> expect(:get_unlock, fn(identifiers, _) ->
          assert identifiers[:id] == request.params["id"]

          {:ok, %Unlock{}}
         end)

      {:ok, _} = Fulfillment.get_unlock(request)
    end
  end

  describe "delete_unlock/1" do
    test "when role is not authorized" do
      request = %AccessRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Fulfillment.delete_unlock(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        user: %User{},
        role: "administrator",
        params: %{ "id" => Ecto.UUID.generate() }
      }

      ServiceMock
      |> expect(:delete_unlock, fn(id, opts) ->
          assert id == request.params["id"]
          assert opts[:account] == account

          {:ok, %Unlock{}}
         end)

      {:ok, _} = Fulfillment.delete_unlock(request)
    end
  end
end
