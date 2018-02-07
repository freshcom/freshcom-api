defmodule BlueJet.Goods.ServiceTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity.Account
  alias BlueJet.Goods.{Stockable, Unlockable, Depositable}
  alias BlueJet.Goods.Service

  describe "list_stockable/2" do
    test "stockable for different account is not returned" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      Repo.insert!(%Stockable{
        account_id: account.id,
        name: Faker.Commerce.product_name(),
        unit_of_measure: "EA"
      })
      Repo.insert!(%Stockable{
        account_id: account.id,
        name: Faker.Commerce.product_name(),
        unit_of_measure: "EA"
      })
      Repo.insert!(%Stockable{
        account_id: other_account.id,
        name: Faker.Commerce.product_name(),
        unit_of_measure: "EA"
      })

      stockables = Service.list_stockable(%{ account: account })
      assert length(stockables) == 2
    end

    test "pagination should change result size" do
      account = Repo.insert!(%Account{})
      Repo.insert!(%Stockable{
        account_id: account.id,
        name: Faker.Commerce.product_name(),
        unit_of_measure: "EA"
      })
      Repo.insert!(%Stockable{
        account_id: account.id,
        name: Faker.Commerce.product_name(),
        unit_of_measure: "EA"
      })
      Repo.insert!(%Stockable{
        account_id: account.id,
        name: Faker.Commerce.product_name(),
        unit_of_measure: "EA"
      })
      Repo.insert!(%Stockable{
        account_id: account.id,
        name: Faker.Commerce.product_name(),
        unit_of_measure: "EA"
      })
      Repo.insert!(%Stockable{
        account_id: account.id,
        name: Faker.Commerce.product_name(),
        unit_of_measure: "EA"
      })

      stockables = Service.list_stockable(%{ account: account, pagination: %{ size: 3, number: 1 } })
      assert length(stockables) == 3

      stockables = Service.list_stockable(%{ account: account, pagination: %{ size: 3, number: 2 } })
      assert length(stockables) == 2
    end
  end

  describe "create_stockable/2" do
    test "when given invalid fields" do
      account = Repo.insert!(%Account{})
      fields = %{}

      {:error, changeset} = Service.create_stockable(fields, %{ account: account })

      assert changeset.valid? == false
    end

    test "when given valid fields" do
      account = Repo.insert!(%Account{})

      fields = %{
        "name" => Faker.Commerce.product_name(),
        "unit_of_measure" => "ea"
      }

      {:ok, stockable} = Service.create_stockable(fields, %{ account: account })

      assert stockable
    end
  end

  describe "get_stockable/2" do
    test "when given id" do
      account = Repo.insert!(%Account{})
      stockable = Repo.insert!(%Stockable{
        account_id: account.id,
        name: Faker.Commerce.product_name(),
        unit_of_measure: "EA"
      })

      assert Service.get_stockable(%{ id: stockable.id }, %{ account: account })
    end

    test "when given id belongs to a different account" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      stockable = Repo.insert!(%Stockable{
        account_id: other_account.id,
        name: Faker.Commerce.product_name(),
        unit_of_measure: "EA"
      })

      refute Service.get_stockable(%{ id: stockable.id }, %{ account: account })
    end

    test "when give id does not exist" do
      account = Repo.insert!(%Account{})

      refute Service.get_stockable(%{ id: Ecto.UUID.generate() }, %{ account: account })
    end
  end

  describe "update_stockable/2" do
    test "when given nil for stockable" do
      {:error, error} = Service.update_stockable(nil, %{}, %{})

      assert error == :not_found
    end

    test "when given id does not exist" do
      account = Repo.insert!(%Account{})

      {:error, error} = Service.update_stockable(Ecto.UUID.generate(), %{}, %{ account: account })

      assert error == :not_found
    end

    test "when given id belongs to a different account" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      stockable = Repo.insert!(%Stockable{
        account_id: other_account.id,
        name: Faker.Commerce.product_name(),
        unit_of_measure: "EA"
      })

      {:error, error} = Service.update_stockable(stockable.id, %{}, %{ account: account })

      assert error == :not_found
    end

    test "when given valid id and valid fields" do
      account = Repo.insert!(%Account{})
      stockable = Repo.insert!(%Stockable{
        account_id: account.id,
        name: Faker.Commerce.product_name(),
        unit_of_measure: "EA"
      })

      fields = %{
        "name" => Faker.Commerce.product_name()
      }

      {:ok, stockable} = Service.update_stockable(stockable.id, fields, %{ account: account })

      assert stockable
    end
  end

  describe "delete_stockable/2" do
    test "when given valid stockable" do
      account = Repo.insert!(%Account{})
      stockable = Repo.insert!(%Stockable{
        account_id: account.id,
        name: Faker.Commerce.product_name(),
        unit_of_measure: "EA"
      })

      {:ok, stockable} = Service.delete_stockable(stockable, %{ account: account })

      assert stockable
      refute Repo.get(Stockable, stockable.id)
    end
  end

  describe "list_unlockable/2" do
    test "unlockable for different account is not returned" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      Repo.insert!(%Unlockable{
        account_id: account.id,
        name: Faker.Commerce.product_name()
      })
      Repo.insert!(%Unlockable{
        account_id: account.id,
        name: Faker.Commerce.product_name()
      })
      Repo.insert!(%Unlockable{
        account_id: other_account.id,
        name: Faker.Commerce.product_name()
      })

      unlockables = Service.list_unlockable(%{ account: account })
      assert length(unlockables) == 2
    end

    test "pagination should change result size" do
      account = Repo.insert!(%Account{})
      Repo.insert!(%Unlockable{
        account_id: account.id,
        name: Faker.Commerce.product_name()
      })
      Repo.insert!(%Unlockable{
        account_id: account.id,
        name: Faker.Commerce.product_name()
      })
      Repo.insert!(%Unlockable{
        account_id: account.id,
        name: Faker.Commerce.product_name()
      })
      Repo.insert!(%Unlockable{
        account_id: account.id,
        name: Faker.Commerce.product_name()
      })
      Repo.insert!(%Unlockable{
        account_id: account.id,
        name: Faker.Commerce.product_name()
      })

      unlockables = Service.list_unlockable(%{ account: account, pagination: %{ size: 3, number: 1 } })
      assert length(unlockables) == 3

      unlockables = Service.list_unlockable(%{ account: account, pagination: %{ size: 3, number: 2 } })
      assert length(unlockables) == 2
    end
  end
end
