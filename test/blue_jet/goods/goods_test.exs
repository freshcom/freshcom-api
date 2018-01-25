defmodule BlueJet.GoodsTest do
  use BlueJet.DataCase

  import Mox
  import BlueJet.Identity.TestHelper

  alias BlueJet.AccessRequest
  alias BlueJet.Goods
  alias BlueJet.Goods.Stockable
  alias BlueJet.Goods.IdentityServiceMock

  describe "list_stockable/1" do
    test "when using customer identity" do
      %{ vas: vas } = create_global_identity("customer")

      {:error, error} =
        %AccessRequest{ vas: vas }
        |> Goods.list_stockable()

      assert error == :access_denied
    end

    test "when using developer identity" do
      %{ vas: vas, account: account } = create_global_identity("developer")

      stockable = Repo.insert!(%Stockable{
        account_id: account.id,
        name: Faker.String.base64(5),
        unit_of_measure: Faker.String.base64(2)
      })

      {:ok, response} =
        %AccessRequest{ vas: vas }
        |> Goods.list_stockable()

      assert length(response.data)
      assert Enum.at(response.data, 0).id == stockable.id
      assert response.meta.locale == account.default_locale
      assert response.meta.all_count == 1
      assert response.meta.total_count == 1
    end
  end

  describe "create_stockable/1" do
    test "when using customer identity" do
      %{ vas: vas } = create_global_identity("customer")

      {:error, error} =
        %AccessRequest{ vas: vas }
        |> Goods.create_stockable()

      assert error == :access_denied
    end

    test "when using developer identity" do
      %{ vas: vas, account: account } = create_global_identity("developer")

      IdentityServiceMock
      |> expect(:get_account, fn(_) -> account end)

      request = %AccessRequest{
        vas: vas,
        fields: %{
          "name" => Faker.String.base64(5),
          "unit_of_measure" => Faker.String.base64(2)
        }
      }
      {:ok, response} = Goods.create_stockable(request)

      verify!()
      assert response.data.id
    end
  end

  describe "get_stockable/1" do
    test "when using customer identity" do
      %{ vas: vas } = create_global_identity("customer")

      {:error, error} =
        %AccessRequest{ vas: vas }
        |> Goods.get_stockable()

      assert error == :access_denied
    end

    test "when using developer identity" do
      %{ vas: vas, account: account } = create_global_identity("developer")
      stockable = Repo.insert!(%Stockable{
        account_id: account.id,
        name: Faker.String.base64(5),
        unit_of_measure: Faker.String.base64(2)
      })
      request = %AccessRequest{
        vas: vas,
        params: %{ "id" => stockable.id }
      }

      {:ok, response} = Goods.get_stockable(request)

      assert response.data.id == stockable.id
    end
  end

  describe "update_stockable/1" do
    test "when using customer identity" do
      %{ vas: vas } = create_global_identity("customer")

      {:error, error} =
        %AccessRequest{ vas: vas }
        |> Goods.update_stockable()

      assert error == :access_denied
    end

    test "when using developer identity" do
      %{ vas: vas, account: account } = create_global_identity("developer")

      IdentityServiceMock
      |> expect(:get_account, fn(_) -> account end)

      stockable = Repo.insert!(%Stockable{
        account_id: account.id,
        name: Faker.String.base64(5),
        unit_of_measure: Faker.String.base64(2)
      })
      new_name = Faker.String.base64(5)
      request = %AccessRequest{
        vas: vas,
        params: %{ "id" => stockable.id },
        fields: %{
          "name" => new_name
        }
      }

      {:ok, response} = Goods.update_stockable(request)

      assert response.data.id == stockable.id
      assert response.data.name == new_name
    end
  end

  describe "delete_stockable/1" do
    test "when using customer identity" do
      %{ vas: vas } = create_global_identity("customer")

      {:error, error} =
        %AccessRequest{ vas: vas }
        |> Goods.delete_stockable()

      assert error == :access_denied
    end

    test "when using developer identity" do
      %{ vas: vas, account: account } = create_global_identity("developer")
      stockable = Repo.insert!(%Stockable{
        account_id: account.id,
        name: Faker.String.base64(5),
        unit_of_measure: Faker.String.base64(2)
      })
      request = %AccessRequest{
        vas: vas,
        params: %{ "id" => stockable.id }
      }

      {:ok, _} = Goods.delete_stockable(request)

      refute Repo.get(Stockable, stockable.id)
    end
  end
end
