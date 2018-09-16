defmodule BlueJet.Goods.DefaultServiceTest do
  use BlueJet.DataCase

  alias BlueJet.Identity.Account
  alias BlueJet.Goods.{Stockable, Unlockable, Depositable}
  alias BlueJet.Goods.DefaultService

  def stockable_fixture(account, fields \\ %{}) do
    default_fields = %{
      name: Faker.Commerce.product_name(),
      unit_of_measure: "EA"
    }
    fields = Map.merge(default_fields, fields)

    {:ok, stockable} = DefaultService.create_stockable(fields, %{account: account})

    stockable
  end

  describe "list_stockable/2 and count_stockable/2" do
    test "with valid request" do
      account1 = account_fixture()
      account2 = account_fixture()

      stockable_fixture(account1, %{label: "colored_shirt", name: "Blue Shirt"})
      stockable_fixture(account1, %{label: "colored_shirt", name: "White Shirt"})
      stockable_fixture(account1, %{label: "colored_shirt", name: "Black Shirt"})
      stockable_fixture(account1, %{name: "Yellow Shirt"})
      stockable_fixture(account1)
      stockable_fixture(account1)

      stockable_fixture(account2, %{label: "colored_shirt", name: "Blue Shirt"})

      query = %{
        filter: %{label: "colored_shirt"},
        search: "shirt"
      }

      stockables = DefaultService.list_stockable(query, %{
        account: account1,
        pagination: %{size: 2, number: 1}
      })

      assert length(stockables) == 2

      stockables = DefaultService.list_stockable(query, %{
        account: account1,
        pagination: %{size: 2, number: 2}
      })

      assert length(stockables) == 1

      assert DefaultService.count_stockable(query, %{account: account1}) == 3
      assert DefaultService.count_stockable(%{}, %{account: account1}) == 6
    end
  end

  describe "create_stockable/2" do
    test "when given invalid fields" do
      account = account_fixture()

      {:error, %{errors: _}} = DefaultService.create_stockable(%{}, %{account: account})
    end

    test "when given valid fields" do
      account = account_fixture()

      fields = %{
        "name" => Faker.Commerce.product_name(),
        "unit_of_measure" => "ea"
      }

      {:ok, stockable} = DefaultService.create_stockable(fields, %{account: account})

      assert stockable.name == fields["name"]
      assert stockable.unit_of_measure == fields["unit_of_measure"]
      assert stockable.account.id == account.id
    end
  end

  describe "get_stockable/2" do
    test "when give id does not exist" do
      account = account_fixture()

      refute DefaultService.get_stockable(%{id: Ecto.UUID.generate()}, %{account: account})
    end

    test "when given id belongs to a different account" do
      account1 = account_fixture()
      account2 = account_fixture()
      stockable = stockable_fixture(account1)

      refute DefaultService.get_stockable(%{id: stockable.id}, %{account: account2})
    end

    test "when given id" do
      account = account_fixture()
      target_stockable = stockable_fixture(account)

      stockable = DefaultService.get_stockable(%{id: target_stockable.id}, %{account: account})

      assert stockable.id == target_stockable.id
      assert stockable.account.id == account.id
    end
  end

  describe "update_stockable/2" do
    test "when given id does not exist" do
      account = account_fixture()

      identifiers = %{id: Ecto.UUID.generate()}
      opts = %{account: account}
      {:error, error} = DefaultService.update_stockable(identifiers, %{}, opts)

      assert error == :not_found
    end

    test "when given id belongs to a different account" do
      account1 = account_fixture()
      account2 = account_fixture()
      stockable = stockable_fixture(account1)

      identifiers = %{id: stockable.id}
      opts = %{account: account2}

      {:error, error} = DefaultService.update_stockable(identifiers, %{}, opts)

      assert error == :not_found
    end

    test "when given valid id and valid fields" do
      account = account_fixture()
      target_stockable = stockable_fixture(account)

      identifiers = %{id: target_stockable.id}
      fields = %{"name" => Faker.Commerce.product_name()}
      opts = %{account: account}

      {:ok, stockable} = DefaultService.update_stockable(identifiers, fields, opts)

      assert stockable.name == fields["name"]
    end
  end

  describe "delete_stockable/2" do
    test "when given id does not exist" do
      account = account_fixture()

      identifiers = %{id: Ecto.UUID.generate()}
      opts = %{account: account}

      {:error, error} = DefaultService.delete_stockable(identifiers, opts)

      assert error == :not_found
    end

    test "when given id belongs to a different account" do
      account1 = account_fixture()
      account2 = account_fixture()
      stockable = stockable_fixture(account1)

      identifiers = %{id: stockable.id}
      opts = %{account: account2}

      {:error, error} = DefaultService.delete_stockable(identifiers, opts)

      assert error == :not_found
    end

    test "when given valid id" do
      account = account_fixture()
      stockable = stockable_fixture(account)

      identifiers = %{id: stockable.id}
      opts = %{account: account}

      {:ok, stockable} = DefaultService.delete_stockable(identifiers, opts)

      assert stockable
      refute Repo.get(Stockable, stockable.id)
    end
  end

  describe "delete_all_stockable/1" do
    test "given valid account" do
      account = account_fixture()
      test_account = account.test_account
      stockable1 = stockable_fixture(test_account)
      stockable2 = stockable_fixture(test_account)

      :ok = DefaultService.delete_all_stockable(%{account: test_account})

      refute Repo.get(Stockable, stockable1.id)
      refute Repo.get(Stockable, stockable2.id)
    end
  end

  # describe "list_unlockable/2" do
  #   test "unlockable for different account is not returned" do
  #     account = Repo.insert!(%Account{})
  #     other_account = Repo.insert!(%Account{})
  #     Repo.insert!(%Unlockable{
  #       account_id: account.id,
  #       name: Faker.Commerce.product_name()
  #     })
  #     Repo.insert!(%Unlockable{
  #       account_id: account.id,
  #       name: Faker.Commerce.product_name()
  #     })
  #     Repo.insert!(%Unlockable{
  #       account_id: other_account.id,
  #       name: Faker.Commerce.product_name()
  #     })

  #     unlockables = DefaultService.list_unlockable(%{ account: account })
  #     assert length(unlockables) == 2
  #   end

  #   test "pagination should change result size" do
  #     account = Repo.insert!(%Account{})
  #     Repo.insert!(%Unlockable{
  #       account_id: account.id,
  #       name: Faker.Commerce.product_name()
  #     })
  #     Repo.insert!(%Unlockable{
  #       account_id: account.id,
  #       name: Faker.Commerce.product_name()
  #     })
  #     Repo.insert!(%Unlockable{
  #       account_id: account.id,
  #       name: Faker.Commerce.product_name()
  #     })
  #     Repo.insert!(%Unlockable{
  #       account_id: account.id,
  #       name: Faker.Commerce.product_name()
  #     })
  #     Repo.insert!(%Unlockable{
  #       account_id: account.id,
  #       name: Faker.Commerce.product_name()
  #     })

  #     unlockables = DefaultService.list_unlockable(%{ account: account, pagination: %{ size: 3, number: 1 } })
  #     assert length(unlockables) == 3

  #     unlockables = DefaultService.list_unlockable(%{ account: account, pagination: %{ size: 3, number: 2 } })
  #     assert length(unlockables) == 2
  #   end
  # end

  # describe "create_unlockable/2" do
  #   test "when given invalid fields" do
  #     account = Repo.insert!(%Account{})
  #     fields = %{}

  #     {:error, changeset} = DefaultService.create_unlockable(fields, %{ account: account })

  #     assert changeset.valid? == false
  #   end

  #   test "when given valid fields" do
  #     account = Repo.insert!(%Account{})

  #     fields = %{
  #       "name" => Faker.Commerce.product_name()
  #     }

  #     {:ok, unlockable} = DefaultService.create_unlockable(fields, %{ account: account })

  #     assert unlockable
  #   end
  # end

  # describe "get_unlockable/2" do
  #   test "when given id" do
  #     account = Repo.insert!(%Account{})
  #     unlockable = Repo.insert!(%Unlockable{
  #       account_id: account.id,
  #       name: Faker.Commerce.product_name()
  #     })

  #     assert DefaultService.get_unlockable(%{ id: unlockable.id }, %{ account: account })
  #   end

  #   test "when given id belongs to a different account" do
  #     account = Repo.insert!(%Account{})
  #     other_account = Repo.insert!(%Account{})
  #     unlockable = Repo.insert!(%Unlockable{
  #       account_id: other_account.id,
  #       name: Faker.Commerce.product_name()
  #     })

  #     refute DefaultService.get_unlockable(%{ id: unlockable.id }, %{ account: account })
  #   end

  #   test "when give id does not exist" do
  #     account = Repo.insert!(%Account{})

  #     refute DefaultService.get_unlockable(%{ id: Ecto.UUID.generate() }, %{ account: account })
  #   end
  # end

  # describe "update_unlockable/2" do
  #   test "when given nil for unlockable" do
  #     {:error, error} = DefaultService.update_unlockable(nil, %{}, %{})

  #     assert error == :not_found
  #   end

  #   test "when given id does not exist" do
  #     account = Repo.insert!(%Account{})

  #     {:error, error} = DefaultService.update_unlockable(%{ id: Ecto.UUID.generate() }, %{}, %{ account: account })

  #     assert error == :not_found
  #   end

  #   test "when given id belongs to a different account" do
  #     account = Repo.insert!(%Account{})
  #     other_account = Repo.insert!(%Account{})
  #     unlockable = Repo.insert!(%Unlockable{
  #       account_id: other_account.id,
  #       name: Faker.Commerce.product_name()
  #     })

  #     {:error, error} = DefaultService.update_unlockable(%{ id: unlockable.id }, %{}, %{ account: account })

  #     assert error == :not_found
  #   end

  #   test "when given valid id and valid fields" do
  #     account = Repo.insert!(%Account{})
  #     unlockable = Repo.insert!(%Unlockable{
  #       account_id: account.id,
  #       name: Faker.Commerce.product_name()
  #     })

  #     fields = %{
  #       "name" => Faker.Commerce.product_name()
  #     }

  #     {:ok, unlockable} = DefaultService.update_unlockable(%{ id: unlockable.id }, fields, %{ account: account })

  #     assert unlockable
  #   end
  # end

  # describe "delete_unlockable/2" do
  #   test "when given valid unlockable" do
  #     account = Repo.insert!(%Account{})
  #     unlockable = Repo.insert!(%Unlockable{
  #       account_id: account.id,
  #       name: Faker.Commerce.product_name()
  #     })

  #     {:ok, unlockable} = DefaultService.delete_unlockable(unlockable, %{ account: account })

  #     assert unlockable
  #     refute Repo.get(Unlockable, unlockable.id)
  #   end
  # end

  # describe "list_depositable/2" do
  #   test "depositable for different account is not returned" do
  #     account = Repo.insert!(%Account{})
  #     other_account = Repo.insert!(%Account{})
  #     Repo.insert!(%Depositable{
  #       account_id: account.id,
  #       name: Faker.Commerce.product_name(),
  #       gateway: "freshcom",
  #       amount: 500
  #     })
  #     Repo.insert!(%Depositable{
  #       account_id: account.id,
  #       name: Faker.Commerce.product_name(),
  #       gateway: "freshcom",
  #       amount: 500
  #     })
  #     Repo.insert!(%Depositable{
  #       account_id: other_account.id,
  #       name: Faker.Commerce.product_name(),
  #       gateway: "freshcom",
  #       amount: 500
  #     })

  #     depositables = DefaultService.list_depositable(%{ account: account })
  #     assert length(depositables) == 2
  #   end

  #   test "pagination should change result size" do
  #     account = Repo.insert!(%Account{})
  #     Repo.insert!(%Depositable{
  #       account_id: account.id,
  #       name: Faker.Commerce.product_name(),
  #       gateway: "freshcom",
  #       amount: 500
  #     })
  #     Repo.insert!(%Depositable{
  #       account_id: account.id,
  #       name: Faker.Commerce.product_name(),
  #       gateway: "freshcom",
  #       amount: 500
  #     })
  #     Repo.insert!(%Depositable{
  #       account_id: account.id,
  #       name: Faker.Commerce.product_name(),
  #       gateway: "freshcom",
  #       amount: 500
  #     })
  #     Repo.insert!(%Depositable{
  #       account_id: account.id,
  #       name: Faker.Commerce.product_name(),
  #       gateway: "freshcom",
  #       amount: 500
  #     })
  #     Repo.insert!(%Depositable{
  #       account_id: account.id,
  #       name: Faker.Commerce.product_name(),
  #       gateway: "freshcom",
  #       amount: 500
  #     })

  #     depositables = DefaultService.list_depositable(%{ account: account, pagination: %{ size: 3, number: 1 } })
  #     assert length(depositables) == 3

  #     depositables = DefaultService.list_depositable(%{ account: account, pagination: %{ size: 3, number: 2 } })
  #     assert length(depositables) == 2
  #   end
  # end

  # describe "create_depositable/2" do
  #   test "when given invalid fields" do
  #     account = Repo.insert!(%Account{})
  #     fields = %{}

  #     {:error, changeset} = DefaultService.create_depositable(fields, %{ account: account })

  #     assert changeset.valid? == false
  #   end

  #   test "when given valid fields" do
  #     account = Repo.insert!(%Account{})

  #     fields = %{
  #       "name" => Faker.Commerce.product_name(),
  #       "gateway" => "freshcom",
  #       "amount" => 500
  #     }

  #     {:ok, depositable} = DefaultService.create_depositable(fields, %{ account: account })

  #     assert depositable
  #   end
  # end

  # describe "get_depositable/2" do
  #   test "when given id" do
  #     account = Repo.insert!(%Account{})
  #     depositable = Repo.insert!(%Depositable{
  #       account_id: account.id,
  #       name: Faker.Commerce.product_name(),
  #       gateway: "freshcom",
  #       amount: 500
  #     })

  #     assert DefaultService.get_depositable(%{ id: depositable.id }, %{ account: account })
  #   end

  #   test "when given id belongs to a different account" do
  #     account = Repo.insert!(%Account{})
  #     other_account = Repo.insert!(%Account{})
  #     depositable = Repo.insert!(%Depositable{
  #       account_id: other_account.id,
  #       name: Faker.Commerce.product_name(),
  #       gateway: "freshcom",
  #       amount: 500
  #     })

  #     refute DefaultService.get_depositable(%{ id: depositable.id }, %{ account: account })
  #   end

  #   test "when give id does not exist" do
  #     account = Repo.insert!(%Account{})

  #     refute DefaultService.get_depositable(%{ id: Ecto.UUID.generate() }, %{ account: account })
  #   end
  # end

  # describe "update_depositable/2" do
  #   test "when given nil for depositable" do
  #     {:error, error} = DefaultService.update_depositable(nil, %{}, %{})

  #     assert error == :not_found
  #   end

  #   test "when given id does not exist" do
  #     account = Repo.insert!(%Account{})

  #     {:error, error} = DefaultService.update_depositable(%{ id: Ecto.UUID.generate() }, %{}, %{ account: account })

  #     assert error == :not_found
  #   end

  #   test "when given id belongs to a different account" do
  #     account = Repo.insert!(%Account{})
  #     other_account = Repo.insert!(%Account{})
  #     depositable = Repo.insert!(%Depositable{
  #       account_id: other_account.id,
  #       name: Faker.Commerce.product_name(),
  #       gateway: "freshcom",
  #       amount: 500
  #     })

  #     {:error, error} = DefaultService.update_depositable(%{ id: depositable.id }, %{}, %{ account: account })

  #     assert error == :not_found
  #   end

  #   test "when given valid id and valid fields" do
  #     account = Repo.insert!(%Account{})
  #     depositable = Repo.insert!(%Depositable{
  #       account_id: account.id,
  #       name: Faker.Commerce.product_name(),
  #       gateway: "freshcom",
  #       amount: 500
  #     })

  #     fields = %{
  #       "name" => Faker.Commerce.product_name()
  #     }

  #     {:ok, depositable} = DefaultService.update_depositable(%{ id: depositable.id }, fields, %{ account: account })

  #     assert depositable
  #   end
  # end

  # describe "delete_depositable/2" do
  #   test "when given valid depositable" do
  #     account = Repo.insert!(%Account{})
  #     depositable = Repo.insert!(%Depositable{
  #       account_id: account.id,
  #       name: Faker.Commerce.product_name(),
  #       gateway: "freshcom",
  #       amount: 500
  #     })

  #     {:ok, depositable} = DefaultService.delete_depositable(depositable, %{ account: account })

  #     assert depositable
  #     refute Repo.get(Depositable, depositable.id)
  #   end
  # end
end
