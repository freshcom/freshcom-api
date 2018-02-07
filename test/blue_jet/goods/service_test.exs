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

  describe "create_unlockable/2" do
    test "when given invalid fields" do
      account = Repo.insert!(%Account{})
      fields = %{}

      {:error, changeset} = Service.create_unlockable(fields, %{ account: account })

      assert changeset.valid? == false
    end

    test "when given valid fields" do
      account = Repo.insert!(%Account{})

      fields = %{
        "name" => Faker.Commerce.product_name()
      }

      {:ok, unlockable} = Service.create_unlockable(fields, %{ account: account })

      assert unlockable
    end
  end

  describe "get_unlockable/2" do
    test "when given id" do
      account = Repo.insert!(%Account{})
      unlockable = Repo.insert!(%Unlockable{
        account_id: account.id,
        name: Faker.Commerce.product_name()
      })

      assert Service.get_unlockable(%{ id: unlockable.id }, %{ account: account })
    end

    test "when given id belongs to a different account" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      unlockable = Repo.insert!(%Unlockable{
        account_id: other_account.id,
        name: Faker.Commerce.product_name()
      })

      refute Service.get_unlockable(%{ id: unlockable.id }, %{ account: account })
    end

    test "when give id does not exist" do
      account = Repo.insert!(%Account{})

      refute Service.get_unlockable(%{ id: Ecto.UUID.generate() }, %{ account: account })
    end
  end

  describe "update_unlockable/2" do
    test "when given nil for unlockable" do
      {:error, error} = Service.update_unlockable(nil, %{}, %{})

      assert error == :not_found
    end

    test "when given id does not exist" do
      account = Repo.insert!(%Account{})

      {:error, error} = Service.update_unlockable(Ecto.UUID.generate(), %{}, %{ account: account })

      assert error == :not_found
    end

    test "when given id belongs to a different account" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      unlockable = Repo.insert!(%Unlockable{
        account_id: other_account.id,
        name: Faker.Commerce.product_name()
      })

      {:error, error} = Service.update_unlockable(unlockable.id, %{}, %{ account: account })

      assert error == :not_found
    end

    test "when given valid id and valid fields" do
      account = Repo.insert!(%Account{})
      unlockable = Repo.insert!(%Unlockable{
        account_id: account.id,
        name: Faker.Commerce.product_name()
      })

      fields = %{
        "name" => Faker.Commerce.product_name()
      }

      {:ok, unlockable} = Service.update_unlockable(unlockable.id, fields, %{ account: account })

      assert unlockable
    end
  end

  describe "delete_unlockable/2" do
    test "when given valid unlockable" do
      account = Repo.insert!(%Account{})
      unlockable = Repo.insert!(%Unlockable{
        account_id: account.id,
        name: Faker.Commerce.product_name()
      })

      {:ok, unlockable} = Service.delete_unlockable(unlockable, %{ account: account })

      assert unlockable
      refute Repo.get(Unlockable, unlockable.id)
    end
  end

  describe "list_depositable/2" do
    test "depositable for different account is not returned" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      Repo.insert!(%Depositable{
        account_id: account.id,
        name: Faker.Commerce.product_name(),
        target_type: "PointAccount",
        amount: 500
      })
      Repo.insert!(%Depositable{
        account_id: account.id,
        name: Faker.Commerce.product_name(),
        target_type: "PointAccount",
        amount: 500
      })
      Repo.insert!(%Depositable{
        account_id: other_account.id,
        name: Faker.Commerce.product_name(),
        target_type: "PointAccount",
        amount: 500
      })

      depositables = Service.list_depositable(%{ account: account })
      assert length(depositables) == 2
    end

    test "pagination should change result size" do
      account = Repo.insert!(%Account{})
      Repo.insert!(%Depositable{
        account_id: account.id,
        name: Faker.Commerce.product_name(),
        target_type: "PointAccount",
        amount: 500
      })
      Repo.insert!(%Depositable{
        account_id: account.id,
        name: Faker.Commerce.product_name(),
        target_type: "PointAccount",
        amount: 500
      })
      Repo.insert!(%Depositable{
        account_id: account.id,
        name: Faker.Commerce.product_name(),
        target_type: "PointAccount",
        amount: 500
      })
      Repo.insert!(%Depositable{
        account_id: account.id,
        name: Faker.Commerce.product_name(),
        target_type: "PointAccount",
        amount: 500
      })
      Repo.insert!(%Depositable{
        account_id: account.id,
        name: Faker.Commerce.product_name(),
        target_type: "PointAccount",
        amount: 500
      })

      depositables = Service.list_depositable(%{ account: account, pagination: %{ size: 3, number: 1 } })
      assert length(depositables) == 3

      depositables = Service.list_depositable(%{ account: account, pagination: %{ size: 3, number: 2 } })
      assert length(depositables) == 2
    end
  end

  describe "create_depositable/2" do
    test "when given invalid fields" do
      account = Repo.insert!(%Account{})
      fields = %{}

      {:error, changeset} = Service.create_depositable(fields, %{ account: account })

      assert changeset.valid? == false
    end

    test "when given valid fields" do
      account = Repo.insert!(%Account{})

      fields = %{
        "name" => Faker.Commerce.product_name(),
        "target_type" => "PointAccount",
        "amount" => 500
      }

      {:ok, depositable} = Service.create_depositable(fields, %{ account: account })

      assert depositable
    end
  end

  describe "get_depositable/2" do
    test "when given id" do
      account = Repo.insert!(%Account{})
      depositable = Repo.insert!(%Depositable{
        account_id: account.id,
        name: Faker.Commerce.product_name(),
        target_type: "PointAccount",
        amount: 500
      })

      assert Service.get_depositable(%{ id: depositable.id }, %{ account: account })
    end

    test "when given id belongs to a different account" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      depositable = Repo.insert!(%Depositable{
        account_id: other_account.id,
        name: Faker.Commerce.product_name(),
        target_type: "PointAccount",
        amount: 500
      })

      refute Service.get_depositable(%{ id: depositable.id }, %{ account: account })
    end

    test "when give id does not exist" do
      account = Repo.insert!(%Account{})

      refute Service.get_depositable(%{ id: Ecto.UUID.generate() }, %{ account: account })
    end
  end

  describe "update_depositable/2" do
    test "when given nil for depositable" do
      {:error, error} = Service.update_depositable(nil, %{}, %{})

      assert error == :not_found
    end

    test "when given id does not exist" do
      account = Repo.insert!(%Account{})

      {:error, error} = Service.update_depositable(Ecto.UUID.generate(), %{}, %{ account: account })

      assert error == :not_found
    end

    test "when given id belongs to a different account" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      depositable = Repo.insert!(%Depositable{
        account_id: other_account.id,
        name: Faker.Commerce.product_name(),
        target_type: "PointAccount",
        amount: 500
      })

      {:error, error} = Service.update_depositable(depositable.id, %{}, %{ account: account })

      assert error == :not_found
    end

    test "when given valid id and valid fields" do
      account = Repo.insert!(%Account{})
      depositable = Repo.insert!(%Depositable{
        account_id: account.id,
        name: Faker.Commerce.product_name(),
        target_type: "PointAccount",
        amount: 500
      })

      fields = %{
        "name" => Faker.Commerce.product_name()
      }

      {:ok, depositable} = Service.update_depositable(depositable.id, fields, %{ account: account })

      assert depositable
    end
  end

  describe "delete_depositable/2" do
    test "when given valid depositable" do
      account = Repo.insert!(%Account{})
      depositable = Repo.insert!(%Depositable{
        account_id: account.id,
        name: Faker.Commerce.product_name(),
        target_type: "PointAccount",
        amount: 500
      })

      {:ok, depositable} = Service.delete_depositable(depositable, %{ account: account })

      assert depositable
      refute Repo.get(Depositable, depositable.id)
    end
  end
end
