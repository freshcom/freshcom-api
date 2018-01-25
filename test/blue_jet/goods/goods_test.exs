defmodule BlueJet.GoodsTest do
  use BlueJet.ContextCase

  alias BlueJet.AuthorizationMock
  alias BlueJet.Identity.Account
  alias BlueJet.Goods
  alias BlueJet.Goods.Stockable

  describe "list_stockable/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Goods.list_stockable(%AccessRequest{})
      assert error == :access_denied
    end

    test "when using developer identity" do
      account = Repo.insert!(%Account{})
      stockable = Repo.insert!(%Stockable{
        account_id: account.id,
        name: Faker.String.base64(5),
        unit_of_measure: Faker.String.base64(2)
      })

      request = %AccessRequest{
        account: account,
        role: "developer"
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, response} = Goods.list_stockable(request)

      assert length(response.data)
      assert Enum.at(response.data, 0).id == stockable.id
      assert response.meta.locale == account.default_locale
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

    test "when using developer identity" do
      account = Repo.insert!(%Account{})

      request = %AccessRequest{
        account: account,
        role: "developer",
        fields: %{
          "name" => Faker.String.base64(5),
          "unit_of_measure" => Faker.String.base64(2)
        }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, response} = Goods.create_stockable(request)

      assert response.data.id
    end
  end

  describe "get_stockable/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Goods.get_stockable(%AccessRequest{})
      assert error == :access_denied
    end

    test "when using developer identity" do
      account = Repo.insert!(%Account{})
      stockable = Repo.insert!(%Stockable{
        account_id: account.id,
        name: Faker.String.base64(5),
        unit_of_measure: Faker.String.base64(2)
      })

      request = %AccessRequest{
        account: account,
        role: "developer",
        params: %{ "id" => stockable.id }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, response} = Goods.get_stockable(request)

      assert response.data.id == stockable.id
    end
  end

  describe "update_stockable/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Goods.update_stockable(%AccessRequest{})
      assert error == :access_denied
    end

    test "when using developer identity" do
      account = Repo.insert!(%Account{})
      stockable = Repo.insert!(%Stockable{
        account_id: account.id,
        name: Faker.String.base64(5),
        unit_of_measure: Faker.String.base64(2)
      })

      new_name = Faker.String.base64(5)
      request = %AccessRequest{
        account: account,
        role: "developer",
        params: %{ "id" => stockable.id },
        fields: %{ "name" => new_name }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, response} = Goods.update_stockable(request)

      assert response.data.id == stockable.id
      assert response.data.name == new_name
    end
  end

  describe "delete_stockable/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Goods.delete_stockable(%AccessRequest{})
      assert error == :access_denied
    end

    test "when using developer identity" do
      account = Repo.insert!(%Account{})
      stockable = Repo.insert!(%Stockable{
        account_id: account.id,
        name: Faker.String.base64(5),
        unit_of_measure: Faker.String.base64(2)
      })

      request = %AccessRequest{
        account: account,
        role: "developer",
        params: %{ "id" => stockable.id }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, _} = Goods.delete_stockable(request)

      refute Repo.get(Stockable, stockable.id)
    end
  end
end
