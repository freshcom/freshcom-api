defmodule BlueJet.GoodsTest do
  use BlueJet.ContextCase

  alias BlueJet.AuthorizationMock
  alias BlueJet.Identity.Account
  alias BlueJet.Goods
  alias BlueJet.Goods.{Stockable, Unlockable}
  alias BlueJet.Goods.ServiceMock

  describe "list_stockable/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Goods.list_stockable(%AccessRequest{})
      assert error == :access_denied
    end

    test "when using customer identity" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        role: "customer"
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      ServiceMock
      |> expect(:list_stockable, fn(params, opts) ->
          assert params[:filter][:status] == "active"
          assert opts[:account] == account

          [%Stockable{}]
         end)
      |> expect(:count_stockable, fn(params, opts) ->
          assert params[:filter][:status] == "active"
          assert opts[:account] == account

          1
         end)
      |> expect(:count_stockable, fn(params, opts) ->
          assert params[:filter][:status] == "active"
          assert opts[:account] == account

          1
         end)

      {:ok, response} = Goods.list_stockable(request)

      assert length(response.data) == 1
      assert response.meta.all_count == 1
      assert response.meta.total_count == 1
    end
  end

  describe "create_stockable/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Goods.create_stockable(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      stockable = %Stockable{}
      request = %AccessRequest{
        account: account,
        fields: %{
          "name" => Faker.Commerce.product_name(),
          "unit_of_measure" => Faker.String.base64(2)
        }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      ServiceMock
      |> expect(:create_stockable, fn(fields, opts) ->
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, stockable}
         end)

      {:ok, response} = Goods.create_stockable(request)

      assert response.data == stockable
    end
  end

  describe "get_stockable/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Goods.get_stockable(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      stockable = %Stockable{}
      request = %AccessRequest{
        account: account,
        params: %{ "id" => Ecto.UUID.generate() }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      ServiceMock
      |> expect(:get_stockable, fn(identifiers, opts) ->
          assert identifiers[:id] == request.params["id"]
          assert opts[:account] == account

          stockable
         end)

      {:ok, response} = Goods.get_stockable(request)

      assert response.data == stockable
    end
  end

  describe "update_stockable/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Goods.update_stockable(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      stockable = %Stockable{}
      request = %AccessRequest{
        account: account,
        params: %{ "id" => stockable.id },
        fields: %{ "name" => Faker.Commerce.product_name() }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      ServiceMock
      |> expect(:update_stockable, fn(id, fields, opts) ->
          assert id == request.params["id"]
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, stockable}
         end)

      {:ok, response} = Goods.update_stockable(request)

      assert response.data == stockable
    end
  end

  describe "delete_stockable/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Goods.delete_stockable(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      stockable = %Stockable{}
      request = %AccessRequest{
        account: account,
        params: %{ "id" => Ecto.UUID.generate() }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      ServiceMock
      |> expect(:delete_stockable, fn(id, opts) ->
          assert id == request.params["id"]
          assert opts[:account] == account

          {:ok, stockable}
         end)

      {:ok, _} = Goods.delete_stockable(request)
    end
  end

  describe "create_unlockable/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Goods.create_unlockable(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      unlockable = %Unlockable{}
      request = %AccessRequest{
        account: account,
        fields: %{
          "name" => Faker.Commerce.product_name()
        }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      ServiceMock
      |> expect(:create_unlockable, fn(fields, opts) ->
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, unlockable}
         end)

      {:ok, response} = Goods.create_unlockable(request)

      assert response.data == unlockable
    end
  end

  describe "update_unlockable/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Goods.update_unlockable(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      unlockable = %Unlockable{}
      request = %AccessRequest{
        account: account,
        role: "developer",
        params: %{ "id" => Ecto.UUID.generate() },
        fields: %{ "name" => Faker.Commerce.product_name() }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      ServiceMock
      |> expect(:update_unlockable, fn(id, fields, opts) ->
          assert id == request.params["id"]
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, unlockable}
         end)

      {:ok, response} = Goods.update_unlockable(request)

      assert response.data == unlockable
    end
  end
end
