defmodule BlueJet.CatalogueTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity.{Account, User}
  alias BlueJet.Catalogue
  alias BlueJet.Catalogue.{Product, ProductCollection, ProductCollectionMembership, Price}
  alias BlueJet.Catalogue.ServiceMock

  #
  # MARK: Product
  #
  describe "list_product/1" do
    test "when role is not authorized" do
      request = %AccessRequest{
        account: nil,
        user: nil,
        role: "anonymous"
      }

      {:error, error} = Catalogue.list_product(request)
      assert error == :access_denied
    end

    test "when role is guest" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        user: %User{},
        role: "guest"
      }

      ServiceMock
      |> expect(:list_product, fn(fields, opts) ->
          assert fields[:filter][:status] == "active"
          assert opts[:account] == account

          [%Product{}]
         end)
      |> expect(:count_product, fn(fields, opts) ->
          assert fields[:filter][:status] == "active"
          assert opts[:account] == account

          1
         end)
      |> expect(:count_product, fn(fields, opts) ->
          assert fields[:filter][:status] == "active"
          assert opts[:account] == account

          1
         end)

      {:ok, response} = Catalogue.list_product(request)

      assert length(response.data) == 1
      assert response.meta.all_count == 1
      assert response.meta.total_count == 1
    end
  end

  describe "create_product/1" do
    test "when role is not authorized" do
      request = %AccessRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, error} = Catalogue.create_product(request)
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        user: %User{},
        role: "administrator",
        fields: %{
          "name" => Faker.Commerce.product_name(),
          "goods_id" => Ecto.UUID.generate(),
          "goods_type" => "Stockable"
        }
      }

      ServiceMock
      |> expect(:create_product, fn(fields, opts) ->
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, %Product{}}
         end)

      {:ok, _} = Catalogue.create_product(request)
    end
  end

  describe "get_product/1" do
    test "when role is not authorized" do
      request = %AccessRequest{
        account: nil,
        user: nil,
        role: "anonymous"
      }

      {:error, error} = Catalogue.get_product(request)
      assert error == :access_denied
    end

    test "when role is guest" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        user: nil,
        role: "guest",
        params: %{ "id" => Ecto.UUID.generate() }
      }

      ServiceMock
      |> expect(:get_product, fn(identifiers, opts) ->
          assert identifiers[:id] == request.params["id"]
          assert identifiers[:status] == "active"
          assert opts[:account] == account

          %Product{}
         end)

      {:ok, _} = Catalogue.get_product(request)
    end
  end

  describe "update_product/1" do
    test "when role is not authorized" do
      request = %AccessRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, error} = Catalogue.update_product(request)
      assert error == :access_denied
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
      |> expect(:update_product, fn(id, fields, opts) ->
          assert id == request.params["id"]
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, %Product{}}
         end)

      {:ok, _} = Catalogue.update_product(request)
    end
  end

  describe "delete_product/1" do
    test "when role is not authorized" do
      request = %AccessRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, error} = Catalogue.delete_product(request)
      assert error == :access_denied
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
      |> expect(:delete_product, fn(id, opts) ->
          assert id == request.params["id"]
          assert opts[:account] == account

          {:ok, %Product{}}
         end)

      {:ok, _} = Catalogue.delete_product(request)
    end
  end

  #
  # MARK: Product Collection
  #
  describe "list_product_collection/1" do
    test "when role is not authorized" do
      request = %AccessRequest{
        account: nil,
        user: nil,
        role: "anonymous"
      }

      {:error, error} = Catalogue.list_product_collection(request)
      assert error == :access_denied
    end

    test "when request has role guest" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        user: %User{},
        role: "guest",
      }

      ServiceMock
      |> expect(:list_product_collection, fn(fields, opts) ->
          assert fields[:filter][:status] == "active"
          assert opts[:account] == account

          [%ProductCollection{}]
         end)
      |> expect(:count_product_collection, fn(fields, opts) ->
          assert fields[:filter][:status] == "active"
          assert opts[:account] == account

          1
         end)
      |> expect(:count_product_collection, fn(fields, opts) ->
          assert fields[:filter][:status] == "active"
          assert opts[:account] == account

          1
         end)

      {:ok, response} = Catalogue.list_product_collection(request)

      assert length(response.data) == 1
      assert response.meta.all_count == 1
      assert response.meta.total_count == 1
    end
  end

  describe "create_product_collection/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Catalogue.create_product_collection(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = Repo.insert!(%Account{})
      product_collection = %ProductCollection{}
      request = %AccessRequest{
        account: account,
        fields: %{
          "name" => Faker.String.base64(5)
        }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:create_product_collection, fn(fields, opts) ->
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, %ProductCollection{}}
         end)

      {:ok, response} = Catalogue.create_product_collection(request)

      assert response.data == product_collection
    end
  end

  describe "get_product_collection/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Catalogue.get_product_collection(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      product_collection = %ProductCollection{}
      request = %AccessRequest{
        account: account,
        params: %{ "id" => product_collection.id }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
        end)

      ServiceMock
      |> expect(:get_product_collection, fn(identifiers, opts) ->
          assert identifiers[:id] == request.params["id"]
          assert opts[:account] == account

          product_collection
         end)

      {:ok, response} = Catalogue.get_product_collection(request)

      assert response.data == product_collection
    end
  end

  describe "update_product_collection/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Catalogue.update_product_collection(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      product_collection = %ProductCollection{}
      request = %AccessRequest{
        account: account,
        params: %{ "id" => Ecto.UUID.generate() },
        fields: %{ "name" => Faker.Commerce.product_name() }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      ServiceMock
      |> expect(:update_product_collection, fn(id, fields, opts) ->
          assert id == request.params["id"]
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, product_collection}
         end)

      {:ok, response} = Catalogue.update_product_collection(request)

      assert response.data == product_collection
    end
  end

  describe "list_product_collection_membership/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Catalogue.list_product_collection_membership(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request has role customer" do
      account = %Account{}
      request = %AccessRequest{
        role: "customer",
        account: account,
        params: %{ "collection_id" => Ecto.UUID.generate() }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      ServiceMock
      |> expect(:list_product_collection_membership, fn(params, opts) ->
          assert params[:filter][:collection_id] == request.params["collection_id"]
          assert params[:filter][:product_status] == "active"
          assert opts[:account] == account

          [%ProductCollectionMembership{}]
         end)
      |> expect(:count_product_collection_membership, fn(params, opts) ->
          assert params[:filter][:collection_id] == request.params["collection_id"]
          assert opts[:account] == account

          1
         end)
      |> expect(:count_product_collection_membership, fn(_, opts) ->
          assert opts[:account] == account

          1
         end)

      {:ok, response} = Catalogue.list_product_collection_membership(request)

      assert length(response.data) == 1
      assert response.meta.all_count == 1
      assert response.meta.total_count == 1
    end
  end

  describe "create_product_collection_membership/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Catalogue.create_product_collection_membership(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      pcm = %ProductCollectionMembership{}
      request = %AccessRequest{
        account: account,
        params: %{ "collection_id" => Ecto.UUID.generate() },
        fields: %{ "product_id" => Ecto.UUID.generate() }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      ServiceMock
      |> expect(:create_product_collection_membership, fn(fields, opts) ->
          assert fields["colleciont_id"] == request.fields["collection_id"]
          assert fields["product_id"] == request.fields["product_id"]
          assert opts[:account] == account

          {:ok, pcm}
         end)

      {:ok, response} = Catalogue.create_product_collection_membership(request)

      assert response.data == pcm
    end
  end

  describe "delete_product_collection_membership/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Catalogue.delete_product_collection_membership(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      pcm = %ProductCollectionMembership{}
      request = %AccessRequest{
        account: account,
        params: %{ "id" => Ecto.UUID.generate() }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      ServiceMock
      |> expect(:delete_product_collection_membership, fn(id, opts) ->
          assert id == request.params["id"]
          assert opts[:account] == account

          {:ok, pcm}
         end)

      {:ok, _} = Catalogue.delete_product_collection_membership(request)
    end
  end

  describe "list_price/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Catalogue.list_price(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request has role customer" do
      account = %Account{}
      request = %AccessRequest{
        role: "customer",
        account: account,
        params: %{ "product_id" => Ecto.UUID.generate() }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      ServiceMock
      |> expect(:list_price, fn(params, opts) ->
          assert params[:filter][:status] == "active"
          assert params[:filter][:product_id] == request.params["product_id"]
          assert opts[:account] == account

          [%Price{}]
         end)
      |> expect(:count_price, fn(params, opts) ->
          assert params[:filter][:status] == "active"
          assert params[:filter][:product_id] == request.params["product_id"]
          assert opts[:account] == account

          1
         end)
      |> expect(:count_price, fn(params, opts) ->
          assert params[:filter][:status] == "active"
          assert params[:filter][:product_id] == request.params["product_id"]
          assert opts[:account] == account

          1
         end)


      {:ok, response} = Catalogue.list_price(request)

      assert length(response.data) == 1
      assert response.meta.all_count == 1
      assert response.meta.total_count == 1
    end
  end

  describe "create_price/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Catalogue.create_price(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      price = %Price{}
      request = %AccessRequest{
        account: account,
        params: %{ "product_id" => Ecto.UUID.generate() },
        fields: %{
          "name" => Faker.String.base64(5),
          "charge_amount_cents" => 500,
          "charge_unit" => Faker.String.base64(2)
        }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:create_price, fn(fields, opts) ->
          assert fields["product_id"] == request.params["product_id"]
          assert fields["name"] == request.fields["name"]
          assert opts[:account] == account

          {:ok, price}
         end)

      {:ok, response} = Catalogue.create_price(request)

      assert response.data == price
    end
  end

  describe "get_price/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Catalogue.get_price(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request has role guest" do
      account = %Account{}
      price = %Price{}
      request = %AccessRequest{
        account: account,
        params: %{ "id" => price.id }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      ServiceMock
      |> expect(:get_price, fn(identifiers, opts) ->
          assert identifiers[:id] == request.params["id"]
          assert opts[:account] == account

          price
         end)

      {:ok, response} = Catalogue.get_price(request)

      assert response.data == price
    end
  end

  describe "update_price/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Catalogue.update_price(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request has role guest" do
      account = %Account{}
      price = %Price{}
      request = %AccessRequest{
        account: account,
        params: %{ "id" => price.id },
        fields: %{ "name" => Faker.String.base64(5) }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:update_price, fn(id, fields, opts) ->
          assert id == request.params["id"]
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, price}
         end)

      {:ok, response} = Catalogue.update_price(request)

      assert response.data == price
    end
  end

  describe "delete_price/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Catalogue.delete_price(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      price = %Price{}

      request = %AccessRequest{
        account: account,
        params: %{ "id" => price.id }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      ServiceMock
      |> expect(:delete_price, fn(id, opts) ->
          assert id == request.params["id"]
          assert opts[:account] == account

          {:ok, price}
         end)

      {:ok, _} = Catalogue.delete_price(request)
    end
  end
end
