defmodule BlueJet.Identity.AccountTest do
  use BlueJet.DataCase

  alias BlueJet.Identity.Account

  test "writable_fields/0" do
    assert Account.writable_fields() == [
      :name,
      :company_name,
      :default_locale,
      :default_auth_method,
      :website_url,
      :support_email,
      :tech_email,
      :caption,
      :description,
      :custom_data
    ]
  end

  describe "schema" do
    test "when live account is deleted test account should be automatically deleted" do
      live_account = Repo.insert!(%Account{
        mode: "live",
        name: Faker.Company.name()
      })
      test_account = Repo.insert!(%Account{
        mode: "test",
        live_account_id: live_account.id,
        name: live_account.name
      })

      Repo.delete!(live_account)
      refute Repo.get(Account, test_account.id)
    end
  end

  describe "changeset/3" do
    test "when name is missing" do
      changeset =
        %Account{}
        |> Account.changeset(:insert, %{})

      assert changeset.valid? == false
      assert changeset.errors[:name]
    end

    test "when default_locale is missing" do
      params = %{
        name: Faker.Company.name(),
        default_locale: nil
      }
      changeset =
        %Account{}
        |> Account.changeset(:insert, params)

      assert changeset.valid? == false
      assert changeset.errors[:default_locale]
    end

    test "when given params is valid" do
      changeset = Account.changeset(%Account{}, :insert, %{
        name: Faker.Company.name()
      })

      assert changeset.valid?
      assert changeset.changes[:name]
    end
  end

  describe "changeset/4" do
    test "when name is set to nil" do
      changeset =
        %Account{}
        |> Account.changeset(:update, %{ name: nil })

      assert changeset.valid? == false
      assert changeset.errors[:name]
    end

    test "when updating default locale should not be changeable" do
      account = %Account{}
      changeset =
        account
        |> Account.changeset(:update, %{ default_locale: "test" })

      refute changeset.changes[:default_locale]
    end
  end

  describe "put_test_account_id/1" do
    test "when given account is a live account" do
      live_account = Repo.insert!(%Account{
        mode: "live",
        name: Faker.Company.name()
      })
      test_account = Repo.insert!(%Account{
        mode: "test",
        live_account_id: live_account.id,
        name: live_account.name
      })

      assert Account.put_test_account_id(live_account).test_account_id == test_account.id
    end

    test "when given account is a test account" do
      account = %Account{ mode: "test" }

      refute Account.put_test_account_id(account).test_account_id
    end
  end
end
