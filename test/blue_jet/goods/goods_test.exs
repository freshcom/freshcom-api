defmodule BlueJet.GoodsTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity.{Account, User}
  alias BlueJet.Goods
  alias BlueJet.Goods.{Stockable, Unlockable, Depositable}
  alias BlueJet.Goods.ServiceMock

  #
  # MARK: Stockable
  #
  describe "list_stockable/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Goods.list_stockable(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator"
      }

      ServiceMock
      |> expect(:list_stockable, fn(_, opts) ->
          assert opts[:account] == account

          [%Stockable{}]
         end)
      |> expect(:count_stockable, fn(_, opts) ->
          assert opts[:account] == account

          1
         end)
      |> expect(:count_stockable, fn(_, opts) ->
          assert opts[:account] == account

          1
         end)

      {:ok, _} = Goods.list_stockable(request)
    end
  end

  describe "create_stockable/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Goods.create_stockable(request)
    end

    test "when request is valid" do
      account = %Account{}
      stockable = %Stockable{}
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator",
        fields: %{
          "name" => Faker.Commerce.product_name(),
          "unit_of_measure" => Faker.String.base64(2)
        }
      }

      ServiceMock
      |> expect(:create_stockable, fn(fields, opts) ->
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, stockable}
         end)

      {:ok, _} = Goods.create_stockable(request)
    end
  end

  describe "get_stockable/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Goods.get_stockable(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator",
        params: %{ "id" => Ecto.UUID.generate() }
      }

      ServiceMock
      |> expect(:get_stockable, fn(identifiers, opts) ->
          assert identifiers[:id] == request.params["id"]
          assert opts[:account] == account

          %Stockable{}
         end)

      {:ok, _} = Goods.get_stockable(request)
    end
  end

  describe "update_stockable/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Goods.update_stockable(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator",
        params: %{ "id" => Ecto.UUID.generate() },
        fields: %{ "name" => Faker.Commerce.product_name() }
      }

      ServiceMock
      |> expect(:update_stockable, fn(identifiers, fields, opts) ->
          assert identifiers[:id] == request.params["id"]
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, %Stockable{}}
         end)

      {:ok, _} = Goods.update_stockable(request)
    end
  end

  describe "delete_stockable/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Goods.delete_stockable(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator",
        params: %{ "id" => Ecto.UUID.generate() }
      }

      ServiceMock
      |> expect(:delete_stockable, fn(identifiers, opts) ->
          assert identifiers[:id] == request.params["id"]
          assert opts[:account] == account

          {:ok, %Stockable{}}
         end)

      {:ok, _} = Goods.delete_stockable(request)
    end
  end

  #
  # MARK: Unlockable
  #
  describe "list_unlockable/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Goods.list_unlockable(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator"
      }

      ServiceMock
      |> expect(:list_unlockable, fn(_, opts) ->
          assert opts[:account] == account

          [%Unlockable{}]
         end)
      |> expect(:count_unlockable, fn(_, opts) ->
          assert opts[:account] == account

          1
         end)
      |> expect(:count_unlockable, fn(_, opts) ->
          assert opts[:account] == account

          1
         end)

      {:ok, _} = Goods.list_unlockable(request)
    end
  end

  describe "create_unlockable/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Goods.create_unlockable(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator",
        fields: %{
          "name" => Faker.Commerce.product_name()
        }
      }

      ServiceMock
      |> expect(:create_unlockable, fn(fields, opts) ->
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, %Unlockable{}}
         end)

      {:ok, _} = Goods.create_unlockable(request)
    end
  end

  describe "get_unlockable/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Goods.get_unlockable(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator",
        params: %{ "id" => Ecto.UUID.generate() }
      }

      ServiceMock
      |> expect(:get_unlockable, fn(identifiers, opts) ->
          assert identifiers[:id] == request.params["id"]
          assert opts[:account] == account

          %Unlockable{}
         end)

      {:ok, _} = Goods.get_unlockable(request)
    end
  end

  describe "update_unlockable/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Goods.update_unlockable(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator",
        params: %{ "id" => Ecto.UUID.generate() },
        fields: %{ "name" => Faker.Commerce.product_name() }
      }

      ServiceMock
      |> expect(:update_unlockable, fn(identifiers, fields, opts) ->
          assert identifiers[:id] == request.params["id"]
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, %Unlockable{}}
         end)

      {:ok, _} = Goods.update_unlockable(request)
    end
  end

  describe "delete_unlockable/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Goods.delete_unlockable(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator",
        params: %{ "id" => Ecto.UUID.generate() }
      }

      ServiceMock
      |> expect(:delete_unlockable, fn(identifiers, opts) ->
          assert identifiers[:id] == request.params["id"]
          assert opts[:account] == account

          {:ok, %Unlockable{}}
         end)

      {:ok, _} = Goods.delete_unlockable(request)
    end
  end

  #
  # MARK: Depositable
  #
  describe "list_depositable/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Goods.list_depositable(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator"
      }

      ServiceMock
      |> expect(:list_depositable, fn(_, opts) ->
          assert opts[:account] == account

          [%Depositable{}]
         end)
      |> expect(:count_depositable, fn(_, opts) ->
          assert opts[:account] == account

          1
         end)
      |> expect(:count_depositable, fn(_, opts) ->
          assert opts[:account] == account

          1
         end)

      {:ok, _} = Goods.list_depositable(request)
    end
  end

  describe "create_depositable/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Goods.create_depositable(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator",
        fields: %{
          "name" => Faker.Commerce.product_name()
        }
      }

      ServiceMock
      |> expect(:create_depositable, fn(fields, opts) ->
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, %Depositable{}}
         end)

      {:ok, _} = Goods.create_depositable(request)
    end
  end

  describe "get_depositable/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Goods.get_depositable(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator",
        params: %{ "id" => Ecto.UUID.generate() }
      }

      ServiceMock
      |> expect(:get_depositable, fn(identifiers, opts) ->
          assert identifiers[:id] == request.params["id"]
          assert opts[:account] == account

          %Depositable{}
         end)

      {:ok, _} = Goods.get_depositable(request)
    end
  end

  describe "update_depositable/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Goods.update_depositable(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator",
        params: %{ "id" => Ecto.UUID.generate() },
        fields: %{ "name" => Faker.Commerce.product_name() }
      }

      ServiceMock
      |> expect(:update_depositable, fn(identifiers, fields, opts) ->
          assert identifiers[:id] == request.params["id"]
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, %Depositable{}}
         end)

      {:ok, _} = Goods.update_depositable(request)
    end
  end

  describe "delete_depositable/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Goods.delete_depositable(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator",
        params: %{ "id" => Ecto.UUID.generate() }
      }

      ServiceMock
      |> expect(:delete_depositable, fn(identifiers, opts) ->
          assert identifiers[:id] == request.params["id"]
          assert opts[:account] == account

          {:ok, %Depositable{}}
         end)

      {:ok, _} = Goods.delete_depositable(request)
    end
  end
end
