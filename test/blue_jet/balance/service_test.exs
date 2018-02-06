defmodule BlueJet.Balance.ServiceTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity.Account
  alias BlueJet.Balance.{Settings, Card}
  alias BlueJet.Balance.Service
  alias BlueJet.Balance.{StripeClientMock, OauthClientMock}

  describe "get_settings/1" do
    test "when given id" do
      account = Repo.insert!(%Account{})
      settings = Repo.insert!(%Settings{
        account_id: account.id
      })

      assert Service.get_settings(%{ account: account })
    end
  end

  describe "update_settings/2" do
    test "when given nil for settings" do
      {:error, error} = Service.update_settings(nil, %{}, %{})
      assert error == :not_found
    end

    test "when given settings and valid fields" do
      account = Repo.insert!(%Account{})
      settings = Repo.insert!(%Settings{
        account_id: account.id
      })

      OauthClientMock
      |> expect(:post, fn(_, _) -> {:ok, %{}} end)

      fields = %{
        "stripe_auth_code" => Faker.String.base64(5)
      }

      {:ok, settings} = Service.update_settings(settings, fields, %{ account: account })

      assert settings
    end
  end

  describe "list_card/2" do
    test "file for different account is not returned" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      Repo.insert!(%Card{ account_id: account.id, status: "saved_by_owner" })
      Repo.insert!(%Card{ account_id: account.id, status: "saved_by_owner" })
      Repo.insert!(%Card{ account_id: other_account.id, status: "saved_by_owner" })

      cards = Service.list_card(%{ account: account })
      assert length(cards) == 2
    end

    test "pagination should change result size" do
      account = Repo.insert!(%Account{})
      Repo.insert!(%Card{
        account_id: account.id,
        status: "saved_by_owner"
      })
      Repo.insert!(%Card{
        account_id: account.id,
        status: "saved_by_owner"
      })
      Repo.insert!(%Card{
        account_id: account.id,
        status: "saved_by_owner"
      })
      Repo.insert!(%Card{
        account_id: account.id,
        status: "saved_by_owner"
      })
      Repo.insert!(%Card{
        account_id: account.id,
        status: "saved_by_owner"
      })

      files = Service.list_card(%{ account: account, pagination: %{ size: 3, number: 1 } })
      assert length(files) == 3

      files = Service.list_card(%{ account: account, pagination: %{ size: 3, number: 2 } })
      assert length(files) == 2
    end
  end

  describe "count_card/2" do
    test "card for different account is not returned" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      Repo.insert!(%Card{ account_id: account.id, status: "saved_by_owner" })
      Repo.insert!(%Card{ account_id: account.id, status: "saved_by_owner" })
      Repo.insert!(%Card{ account_id: other_account.id, status: "saved_by_owner" })

      assert Service.count_card(%{ account: account }) == 2
    end

    test "only card matching filter is counted" do
      account = Repo.insert!(%Account{})
      Repo.insert!(%Account{})
      Repo.insert!(%Card{ account_id: account.id, status: "saved_by_owner" })
      Repo.insert!(%Card{ account_id: account.id, status: "saved_by_owner" })
      Repo.insert!(%Card{ account_id: account.id, status: "saved_by_owner", label: "test" })

      assert Service.count_card(%{ filter: %{ label: "test" } }, %{ account: account }) == 1
    end
  end

  describe "update_card/2" do
    test "when given nil for card" do
      {:error, error} = Service.update_card(nil, %{}, %{})
      assert error == :not_found
    end

    test "when given id does not exist" do
      account = Repo.insert!(%Account{})

      {:error, error} = Service.update_card(Ecto.UUID.generate(), %{}, %{ account: account })
      assert error == :not_found
    end

    test "when given id belongs to a different account" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      card = Repo.insert!(%Card{
        account_id: other_account.id,
        status: "saved_by_owner"
      })

      {:error, error} = Service.update_card(card.id, %{}, %{ account: account })
      assert error == :not_found
    end

    test "when given valid id and invalid fields" do
      account = Repo.insert!(%Account{})
      card = Repo.insert!(%Card{
        account_id: account.id,
        status: "saved_by_owner"
      })

      {:error, changeset} = Service.update_card(card.id, %{ "status" => nil }, %{ account: account })
      assert length(changeset.errors) > 0
    end

    test "when given valid id and valid fields" do
      account = Repo.insert!(%Account{})
      card = Repo.insert!(%Card{
        account_id: account.id,
        status: "saved_by_owner",
        exp_year: 2022,
        owner_id: Ecto.UUID.generate(),
        owner_type: "Customer"
      })

      StripeClientMock
      |> expect(:post, fn(_, _, _) -> {:ok, nil} end)

      fields = %{
        "exp_month" => 11
      }

      {:ok, card} = Service.update_card(card.id, fields, %{ account: account })
      assert card
    end

    test "when given card and invalid fields" do
      account = Repo.insert!(%Account{})
      card = Repo.insert!(%Card{
        account_id: account.id,
        status: "saved_by_owner"
      })

      {:error, changeset} = Service.update_card(card, %{ "status" => nil }, %{ account: account })
      assert length(changeset.errors) > 0
    end

    test "when given card and valid fields" do
      account = Repo.insert!(%Account{})
      card = Repo.insert!(%Card{
        account_id: account.id,
        status: "saved_by_owner",
        exp_year: 2022,
        owner_id: Ecto.UUID.generate(),
        owner_type: "Customer"
      })

      StripeClientMock
      |> expect(:post, fn(_, _, _) -> {:ok, nil} end)

      fields = %{
        "exp_month" => 11
      }

      {:ok, card} = Service.update_card(card, fields, %{ account: account })
      assert card
    end
  end

  describe "delete_card/2" do
    test "when given valid card" do
      account = Repo.insert!(%Account{})
      card = Repo.insert!(%Card{
        account_id: account.id,
        status: "saved_by_owner"
      })

      StripeClientMock
      |> expect(:delete, fn(_, _) -> {:ok, nil} end)

      {:ok, card} = Service.delete_card(card, %{ account: account })

      assert card
      refute Repo.get(Card, card.id)
    end
  end
end
