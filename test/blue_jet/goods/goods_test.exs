defmodule BlueJet.GoodsTest do
  use BlueJet.ContextCase

  import BlueJet.Goods.TestHelper

  alias BlueJet.Goods
  alias BlueJet.Goods.{Stockable, Unlockable, Depositable}

  #
  # MARK: Stockable
  #
  describe "list_stockable/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        vas: %{account_id: nil, user_id: nil}
      }

      {:error, :access_denied} = Goods.list_stockable(request)
    end

    test "when request with no locale" do
      user = standard_user_fixture()
      stockable1 = stockable_fixture(user.default_account)
      stockable2 = stockable_fixture(user.default_account)

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id}
      }

      {:ok, response} = Goods.list_stockable(request)

      assert length(response.data) == 2
      assert match(Enum.map(response.data, &Map.get(&1, :name)), [stockable1.name, stockable2.name])
    end

    test "when request with locale" do
      user = standard_user_fixture()
      stockable_fixture(user.default_account)
      stockable_fixture(user.default_account)

      locale = "zh-CN"

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
        locale: locale
      }

      {:ok, response} = Goods.list_stockable(request)

      assert response.meta.locale == locale
      assert length(response.data) == 2

      stockable = Enum.at(response.data, 0)
      assert stockable.name == stockable.translations[locale]["name"]
    end
  end

  describe "create_stockable/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        vas: %{account_id: nil, user_id: nil}
      }

      {:error, :access_denied} = Goods.create_stockable(request)
    end

    test "when given fields are invalid" do
      user = standard_user_fixture()

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
      }

      {:error, %{errors: errors}} = Goods.create_stockable(request)

      assert match_keys(errors, [:name, :unit_of_measure])
    end

    test "when request is valid" do
      user = standard_user_fixture()

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
        fields: %{
          "name" => Faker.Commerce.product_name(),
          "unit_of_measure" => Faker.String.base64(2)
        }
      }

      {:ok, response} = Goods.create_stockable(request)

      assert response.data.name == request.fields["name"]
      assert response.data.unit_of_measure == request.fields["unit_of_measure"]
    end
  end

  describe "get_stockable/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        vas: %{account_id: nil, user_id: nil}
      }

      {:error, :access_denied} = Goods.get_stockable(request)
    end

    test "when given id does not exist" do
      user = standard_user_fixture()

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
        identifiers: %{id: UUID.generate()}
      }

      {:error, :not_found} = Goods.get_stockable(request)
    end

    test "when request is valid" do
      user = standard_user_fixture()
      stockable = stockable_fixture(user.default_account)

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
        identifiers: %{id: stockable.id}
      }

      {:ok, response} = Goods.get_stockable(request)

      assert response.data.id == stockable.id
    end
  end

  describe "update_stockable/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        vas: %{account_id: nil, user_id: nil}
      }

      {:error, :access_denied} = Goods.update_stockable(request)
    end

    test "when given id does not exist" do
      user = standard_user_fixture()

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
        identifiers: %{id: UUID.generate()}
      }

      {:error, :not_found} = Goods.update_stockable(request)
    end

    test "when given fields are invalid" do
      user = standard_user_fixture()
      stockable = stockable_fixture(user.default_account)

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
        identifiers: %{id: stockable.id},
        fields: %{"name" => ""}
      }

      {:error, %{errors: errors}} = Goods.update_stockable(request)

      assert match_keys(errors, [:name])
    end

    test "when given fields are valid" do
      user = standard_user_fixture()
      stockable = stockable_fixture(user.default_account)

      locale = "zh-CN"

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
        identifiers: %{id: stockable.id},
        fields: %{"name" => Faker.Commerce.product_name},
        locale: "zh-CN"
      }

      {:ok, response} = Goods.update_stockable(request)

      assert response.meta.locale == locale
      assert response.data.name == request.fields["name"]
    end
  end

  describe "delete_stockable/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        vas: %{account_id: nil, user_id: nil}
      }

      {:error, :access_denied} = Goods.delete_stockable(request)
    end

    test "when given id does not exist" do
      user = standard_user_fixture()

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
        identifiers: %{id: UUID.generate()}
      }

      {:error, :not_found} = Goods.delete_stockable(request)
    end

    test "when given id is valid" do
      user = standard_user_fixture()
      stockable = stockable_fixture(user.default_account)

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
        identifiers: %{id: stockable.id}
      }

      {:ok, _} = Goods.delete_stockable(request)

      refute Repo.get(Stockable, stockable.id)
    end
  end

  #
  # MARK: Unlockable
  #
  describe "list_unlockable/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        vas: %{account_id: nil, user_id: nil}
      }

      {:error, :access_denied} = Goods.list_unlockable(request)
    end

    test "when request with no locale" do
      user = standard_user_fixture()
      unlockable1 = unlockable_fixture(user.default_account)
      unlockable2 = unlockable_fixture(user.default_account)

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id}
      }

      {:ok, response} = Goods.list_unlockable(request)

      assert length(response.data) == 2
      assert match(Enum.map(response.data, &Map.get(&1, :name)), [unlockable1.name, unlockable2.name])
    end

    test "when request with locale" do
      user = standard_user_fixture()
      unlockable_fixture(user.default_account)
      unlockable_fixture(user.default_account)

      locale = "zh-CN"

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
        locale: locale
      }

      {:ok, response} = Goods.list_unlockable(request)

      assert response.meta.locale == locale
      assert length(response.data) == 2

      unlockable = Enum.at(response.data, 0)
      assert unlockable.name == unlockable.translations[locale]["name"]
    end
  end

  describe "create_unlockable/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        vas: %{account_id: nil, user_id: nil}
      }

      {:error, :access_denied} = Goods.create_unlockable(request)
    end

    test "when given fields are invalid" do
      user = standard_user_fixture()

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
      }

      {:error, %{errors: errors}} = Goods.create_unlockable(request)

      assert match_keys(errors, [:name])
    end

    test "when request is valid" do
      user = standard_user_fixture()

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
        fields: %{"name" => Faker.Commerce.product_name()}
      }

      {:ok, response} = Goods.create_unlockable(request)

      assert response.data.name == request.fields["name"]
    end
  end

  describe "get_unlockable/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        vas: %{account_id: nil, user_id: nil}
      }

      {:error, :access_denied} = Goods.get_unlockable(request)
    end

    test "when given id does not exist" do
      user = standard_user_fixture()

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
        identifiers: %{id: UUID.generate()}
      }

      {:error, :not_found} = Goods.get_unlockable(request)
    end

    test "when request is valid" do
      user = standard_user_fixture()
      unlockable = unlockable_fixture(user.default_account)

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
        identifiers: %{id: unlockable.id}
      }

      {:ok, response} = Goods.get_unlockable(request)

      assert response.data.id == unlockable.id
    end
  end

  describe "update_unlockable/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        vas: %{account_id: nil, user_id: nil}
      }

      {:error, :access_denied} = Goods.update_unlockable(request)
    end

    test "when given id does not exist" do
      user = standard_user_fixture()

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
        identifiers: %{id: UUID.generate()}
      }

      {:error, :not_found} = Goods.update_unlockable(request)
    end

    test "when given fields are invalid" do
      user = standard_user_fixture()
      unlockable = unlockable_fixture(user.default_account)

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
        identifiers: %{id: unlockable.id},
        fields: %{"name" => ""}
      }

      {:error, %{errors: errors}} = Goods.update_unlockable(request)

      assert match_keys(errors, [:name])
    end

    test "when given fields are valid" do
      user = standard_user_fixture()
      unlockable = unlockable_fixture(user.default_account)

      locale = "zh-CN"

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
        identifiers: %{id: unlockable.id},
        fields: %{"name" => Faker.Commerce.product_name},
        locale: "zh-CN"
      }

      {:ok, response} = Goods.update_unlockable(request)

      assert response.meta.locale == locale
      assert response.data.name == request.fields["name"]
    end
  end

  describe "delete_unlockable/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        vas: %{account_id: nil, user_id: nil}
      }

      {:error, :access_denied} = Goods.delete_unlockable(request)
    end

    test "when given id does not exist" do
      user = standard_user_fixture()

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
        identifiers: %{id: UUID.generate()}
      }

      {:error, :not_found} = Goods.delete_unlockable(request)
    end

    test "when given id is valid" do
      user = standard_user_fixture()
      unlockable = unlockable_fixture(user.default_account)

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
        identifiers: %{id: unlockable.id}
      }

      {:ok, _} = Goods.delete_unlockable(request)

      refute Repo.get(Unlockable, unlockable.id)
    end
  end

  #
  # MARK: Depositable
  #
  describe "list_depositable/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        vas: %{account_id: nil, user_id: nil}
      }

      {:error, :access_denied} = Goods.list_depositable(request)
    end

    test "when request with no locale" do
      user = standard_user_fixture()
      depositable1 = depositable_fixture(user.default_account)
      depositable2 = depositable_fixture(user.default_account)

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id}
      }

      {:ok, response} = Goods.list_depositable(request)

      assert length(response.data) == 2
      assert match(Enum.map(response.data, &Map.get(&1, :name)), [depositable1.name, depositable2.name])
    end

    test "when request with locale" do
      user = standard_user_fixture()
      depositable_fixture(user.default_account)
      depositable_fixture(user.default_account)

      locale = "zh-CN"

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
        locale: locale
      }

      {:ok, response} = Goods.list_depositable(request)

      assert response.meta.locale == locale
      assert length(response.data) == 2

      depositable = Enum.at(response.data, 0)
      assert depositable.name == depositable.translations[locale]["name"]
    end
  end

  describe "create_depositable/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        vas: %{account_id: nil, user_id: nil}
      }

      {:error, :access_denied} = Goods.create_depositable(request)
    end

    test "when given fields are invalid" do
      user = standard_user_fixture()

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
      }

      {:error, %{errors: errors}} = Goods.create_depositable(request)

      assert match_keys(errors, [:name, :gateway, :amount])
    end

    test "when request is valid" do
      user = standard_user_fixture()

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
        fields: %{
          "name" => Faker.Commerce.product_name(),
          "gateway" => "freshcom",
          "amount" => System.unique_integer([:positive])
        }
      }

      {:ok, response} = Goods.create_depositable(request)

      assert response.data.name == request.fields["name"]
      assert response.data.gateway == request.fields["gateway"]
      assert response.data.amount == request.fields["amount"]
    end
  end

  describe "get_depositable/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        vas: %{account_id: nil, user_id: nil}
      }

      {:error, :access_denied} = Goods.get_depositable(request)
    end

    test "when given id does not exist" do
      user = standard_user_fixture()

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
        identifiers: %{id: UUID.generate()}
      }

      {:error, :not_found} = Goods.get_depositable(request)
    end

    test "when request is valid" do
      user = standard_user_fixture()
      depositable = depositable_fixture(user.default_account)

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
        identifiers: %{id: depositable.id}
      }

      {:ok, response} = Goods.get_depositable(request)

      assert response.data.id == depositable.id
    end
  end

  describe "update_depositable/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        vas: %{account_id: nil, user_id: nil}
      }

      {:error, :access_denied} = Goods.update_depositable(request)
    end

    test "when given id does not exist" do
      user = standard_user_fixture()

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
        identifiers: %{id: UUID.generate()}
      }

      {:error, :not_found} = Goods.update_depositable(request)
    end

    test "when given fields are invalid" do
      user = standard_user_fixture()
      depositable = depositable_fixture(user.default_account)

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
        identifiers: %{id: depositable.id},
        fields: %{"name" => ""}
      }

      {:error, %{errors: errors}} = Goods.update_depositable(request)

      assert match_keys(errors, [:name])
    end

    test "when given fields are valid" do
      user = standard_user_fixture()
      depositable = depositable_fixture(user.default_account)

      locale = "zh-CN"

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
        identifiers: %{id: depositable.id},
        fields: %{"name" => Faker.Commerce.product_name},
        locale: "zh-CN"
      }

      {:ok, response} = Goods.update_depositable(request)

      assert response.meta.locale == locale
      assert response.data.name == request.fields["name"]
    end
  end

  describe "delete_depositable/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        vas: %{account_id: nil, user_id: nil}
      }

      {:error, :access_denied} = Goods.delete_depositable(request)
    end

    test "when given id does not exist" do
      user = standard_user_fixture()

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
        identifiers: %{id: UUID.generate()}
      }

      {:error, :not_found} = Goods.delete_depositable(request)
    end

    test "when given id is valid" do
      user = standard_user_fixture()
      depositable = depositable_fixture(user.default_account)

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
        identifiers: %{id: depositable.id}
      }

      {:ok, _} = Goods.delete_depositable(request)

      refute Repo.get(Depositable, depositable.id)
    end
  end

end
