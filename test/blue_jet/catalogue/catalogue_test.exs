defmodule BlueJet.BalanceTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity.Account
  alias BlueJet.FileStorage.ExternalFile
  alias BlueJet.Catalogue
  alias BlueJet.Catalogue.{Product, ProductCollection, ProductCollectionMembership, Price}
  alias BlueJet.Catalogue.{GoodsServiceMock, FileStorageServiceMock}

  describe "list_product/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Catalogue.list_product(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request has role guest" do
      account = Repo.insert!(%Account{})
      Repo.insert!(%Product{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      Repo.insert!(%Product{
        account_id: account.id,
        status: "active",
        name: Faker.String.base64(5)
      })

      request = %AccessRequest{
        role: "guest",
        account: account
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, response} = Catalogue.list_product(request)
      assert length(response.data) == 1
      assert response.meta.all_count == 1
      assert response.meta.total_count == 1
    end
  end

  describe "create_product/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Catalogue.create_product(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = Repo.insert!(%Account{})

      request = %AccessRequest{
        role: "developer",
        account: account,
        fields: %{
          "name" => Faker.String.base64(5),
          "source_id" => Ecto.UUID.generate(),
          "source_type" => "Stockable"
        }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      GoodsServiceMock
      |> expect(:get_goods, fn(_, _) -> %{ account_id: account.id } end)

      {:ok, response} = Catalogue.create_product(request)
      assert response.data
    end
  end

  describe "get_product/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Catalogue.get_product(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = Repo.insert!(%Account{})
      product = Repo.insert!(%Product{
        account_id: account.id,
        name: Faker.String.base64(5),
        source_id: Ecto.UUID.generate(),
        source_type: "Stockable"
      })

      request = %AccessRequest{
        role: "developer",
        account: account,
        params: %{ "id" => product.id }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, response} = Catalogue.get_product(request)
      assert response.data.id == product.id
    end
  end

  describe "update_product/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Catalogue.update_product(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = Repo.insert!(%Account{})
      product = Repo.insert!(%Product{
        account_id: account.id,
        name: Faker.String.base64(5),
        source_id: Ecto.UUID.generate(),
        source_type: "Stockable"
      })

      request = %AccessRequest{
        role: "developer",
        account: account,
        params: %{ "id" => product.id },
        fields: %{
          "name" => Faker.String.base64(5)
        }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      GoodsServiceMock
      |> expect(:get_goods, fn(_, _) -> %{ account_id: account.id } end)

      {:ok, response} = Catalogue.update_product(request)
      assert response.data.id == product.id
    end
  end

  describe "delete_product/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Catalogue.delete_product(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = Repo.insert!(%Account{})
      avatar = Repo.insert!(%ExternalFile{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      product = Repo.insert!(%Product{
        account_id: account.id,
        avatar_id: avatar.id,
        name: Faker.String.base64(5),
        source_id: Ecto.UUID.generate(),
        source_type: "Stockable"
      })

      request = %AccessRequest{
        role: "developer",
        account: account,
        params: %{ "id" => product.id }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      FileStorageServiceMock
      |> expect(:delete_external_file, fn(_) -> nil end)

      {:ok, _} = Catalogue.delete_product(request)
    end
  end

  describe "list_product_collection/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Catalogue.list_product_collection(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request has role guest" do
      account = Repo.insert!(%Account{})
      Repo.insert!(%ProductCollection{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      Repo.insert!(%ProductCollection{
        account_id: account.id,
        status: "active",
        name: Faker.String.base64(5)
      })

      request = %AccessRequest{
        role: "guest",
        account: account
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

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

      request = %AccessRequest{
        role: "developer",
        account: account,
        fields: %{
          "name" => Faker.String.base64(5)
        }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, response} = Catalogue.create_product_collection(request)
      assert response.data
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
      account = Repo.insert!(%Account{})
      product_collection = Repo.insert!(%ProductCollection{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      request = %AccessRequest{
        role: "developer",
        account: account,
        params: %{ "id" => product_collection.id }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, response} = Catalogue.get_product_collection(request)
      assert response.data.id == product_collection.id
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
      account = Repo.insert!(%Account{})
      product_collection = Repo.insert!(%ProductCollection{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      request = %AccessRequest{
        role: "developer",
        account: account,
        params: %{ "id" => product_collection.id },
        fields: %{ "name" => Faker.String.base64(5) }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, response} = Catalogue.update_product_collection(request)
      assert response.data.id == product_collection.id
    end
  end

  describe "list_product_collection_membership/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Catalogue.list_product_collection_membership(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request has role guest" do
      account = Repo.insert!(%Account{})
      collection = Repo.insert!(%ProductCollection{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      product1 = Repo.insert!(%Product{
        account_id: account.id,
        name: Faker.String.base64(5),
        source_id: Ecto.UUID.generate(),
        source_type: "Stockable"
      })
      product2 = Repo.insert!(%Product{
        account_id: account.id,
        status: "active",
        name: Faker.String.base64(5),
        source_id: Ecto.UUID.generate(),
        source_type: "Stockable"
      })
      Repo.insert!(%ProductCollectionMembership{
        account_id: account.id,
        collection_id: collection.id,
        product_id: product1.id
      })
      Repo.insert!(%ProductCollectionMembership{
        account_id: account.id,
        collection_id: collection.id,
        product_id: product2.id
      })

      request = %AccessRequest{
        role: "guest",
        account: account,
        params: %{ "collection_id" => collection.id }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

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
      account = Repo.insert!(%Account{})
      collection = Repo.insert!(%ProductCollection{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      product = Repo.insert!(%Product{
        account_id: account.id,
        name: Faker.String.base64(5),
        source_id: Ecto.UUID.generate(),
        source_type: "Stockable"
      })

      request = %AccessRequest{
        role: "guest",
        account: account,
        params: %{ "collection_id" => collection.id },
        fields: %{ "product_id" => product.id }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, response} = Catalogue.create_product_collection_membership(request)
      assert response.data
    end
  end

  # describe "get_product_collection_membership/1" do
  #   test "when role is not authorized" do
  #     AuthorizationMock
  #     |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

  #     {:error, error} = Catalogue.get_product_collection_membership(%AccessRequest{})
  #     assert error == :access_denied
  #   end

  #   test "when request is valid" do
  #     account = Repo.insert!(%Account{})
  #     collection = Repo.insert!(%ProductCollection{
  #       account_id: account.id,
  #       name: Faker.String.base64(5)
  #     })
  #     product = Repo.insert!(%Product{
  #       account_id: account.id,
  #       name: Faker.String.base64(5),
  #       source_id: Ecto.UUID.generate(),
  #       source_type: "Stockable"
  #     })
  #     pcm = Repo.insert!(%ProductCollectionMembership{
  #       account_id: account.id,
  #       collection_id: collection.id,
  #       product_id: product.id
  #     })

  #     request = %AccessRequest{
  #       role: "developer",
  #       account: account,
  #       params: %{ "id" => pcm.id }
  #     }
  #     AuthorizationMock
  #     |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

  #     {:ok, response} = Catalogue.get_product_collection_membership(request)
  #     assert response.data.id == pcm.id
  #   end
  # end

  describe "delete_product_collection_membership/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Catalogue.delete_product_collection_membership(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = Repo.insert!(%Account{})
      collection = Repo.insert!(%ProductCollection{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      product = Repo.insert!(%Product{
        account_id: account.id,
        name: Faker.String.base64(5),
        source_id: Ecto.UUID.generate(),
        source_type: "Stockable"
      })
      pcm = Repo.insert!(%ProductCollectionMembership{
        account_id: account.id,
        collection_id: collection.id,
        product_id: product.id
      })

      request = %AccessRequest{
        role: "developer",
        account: account,
        params: %{ "id" => pcm.id }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

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

    test "when request has role guest" do
      account = Repo.insert!(%Account{})
      product = Repo.insert!(%Product{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      Repo.insert!(%Price{
        account_id: account.id,
        product_id: product.id,
        name: Faker.String.base64(5),
        charge_amount_cents: 500,
        charge_unit: Faker.String.base64(2),
        order_unit: Faker.String.base64(2)
      })
      Repo.insert!(%Price{
        account_id: account.id,
        product_id: product.id,
        status: "active",
        name: Faker.String.base64(5),
        charge_amount_cents: 500,
        charge_unit: Faker.String.base64(2),
        order_unit: Faker.String.base64(2)
      })

      request = %AccessRequest{
        role: "guest",
        account: account,
        params: %{ "product_id" => product.id }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

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
      account = Repo.insert!(%Account{})
      product = Repo.insert!(%Product{
        account_id: account.id,
        name: Faker.String.base64(5)
      })

      request = %AccessRequest{
        role: "developer",
        account: account,
        params: %{ "product_id" => product.id },
        fields: %{
          "name" => Faker.String.base64(5),
          "charge_amount_cents" => 500,
          "charge_unit" => Faker.String.base64(2)
        }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, response} = Catalogue.create_price(request)
      assert response.data
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
      account = Repo.insert!(%Account{})
      product = Repo.insert!(%Product{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      price = Repo.insert!(%Price{
        account_id: account.id,
        product_id: product.id,
        name: Faker.String.base64(5),
        charge_amount_cents: 500,
        charge_unit: Faker.String.base64(2),
        order_unit: Faker.String.base64(2)
      })

      request = %AccessRequest{
        role: "developer",
        account: account,
        params: %{ "id" => price.id }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, response} = Catalogue.get_price(request)
      assert response.data.id == price.id
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
      account = Repo.insert!(%Account{})
      product = Repo.insert!(%Product{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      price = Repo.insert!(%Price{
        account_id: account.id,
        product_id: product.id,
        name: Faker.String.base64(5),
        charge_amount_cents: 500,
        charge_unit: Faker.String.base64(2),
        order_unit: Faker.String.base64(2)
      })

      request = %AccessRequest{
        role: "developer",
        account: account,
        params: %{ "id" => price.id },
        fields: %{ "name" => Faker.String.base64(5) }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, response} = Catalogue.update_price(request)
      assert response.data.id == price.id
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
      account = Repo.insert!(%Account{})
      product = Repo.insert!(%Product{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      price = Repo.insert!(%Price{
        account_id: account.id,
        product_id: product.id,
        status: "disabled",
        name: Faker.String.base64(5),
        charge_amount_cents: 500,
        charge_unit: Faker.String.base64(2),
        order_unit: Faker.String.base64(2)
      })

      request = %AccessRequest{
        role: "developer",
        account: account,
        params: %{ "id" => price.id }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, _} = Catalogue.delete_price(request)
    end
  end
end
