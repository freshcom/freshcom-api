defmodule BlueJet.AccountTest do
  use BlueJet.DataCase

  alias BlueJet.Identity.Account

  test "writable_fields/0" do
    assert Account.writable_fields() == [
      :name,
      :company_name,
      :default_locale,
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
        name: Faker.Company.name(),
        default_locale: "en"
      })
      test_account = Repo.insert!(%Account{
        mode: "test",
        live_account_id: live_account.id,
        name: live_account.name,
        default_locale: live_account.default_locale
      })

      Repo.delete!(live_account)
      refute Repo.get(Account, test_account.id)
    end
  end

  describe "changeset/3" do
    test "when given params is invalid" do
      changeset = Account.changeset(%Account{}, %{
        name: Faker.Company.name(),
        default_locale: "en"
      })

      assert changeset.valid?
    end

    test "when given params is valid" do
      changeset = Account.changeset(%Account{}, %{})

      refute changeset.valid?
    end
  end

  describe "put_test_account_id/1" do
    test "when given account is a live account" do
      live_account = Repo.insert!(%Account{
        mode: "live",
        name: Faker.Company.name(),
        default_locale: "en"
      })
      test_account = Repo.insert!(%Account{
        mode: "test",
        live_account_id: live_account.id,
        name: live_account.name,
        default_locale: live_account.default_locale
      })

      assert Account.put_test_account_id(live_account).test_account_id == test_account.id
    end

    test "when given account is a test account" do
      account = %Account{ mode: "test" }

      refute Account.put_test_account_id(account).test_account_id
    end
  end
end
