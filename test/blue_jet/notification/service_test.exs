defmodule BlueJet.Notification.ServiceTest do
  use BlueJet.ContextCase

  import BlueJet.Notification.TestHelper

  alias BlueJet.Identity.Account
  alias BlueJet.Notification.Service

  describe "update_trigger/2" do
    test "when given id does not exist" do
      account = %{id: UUID.generate()}

      {:error, error} = Service.update_trigger(%{id: UUID.generate()}, %{}, %{account: account})

      assert error == :not_found
    end

    test "when given id belongs to a different account" do
      account1 = account_fixture()
      account2 = account_fixture()
      trigger = trigger_fixture(account2)

      {:error, error} = Service.update_trigger(%{id: trigger.id}, %{}, %{account: account1})

      assert error == :not_found
    end

    test "when given valid id and valid fields" do
      account = account_fixture()
      target_trigger = trigger_fixture(account)

      fields = %{"name" => Faker.Lorem.sentence(5)}

      {:ok, trigger} = Service.update_trigger(%{id: target_trigger.id}, fields, %{account: account})

      assert trigger.id == target_trigger.id
      assert trigger.name == fields["name"]
    end
  end

  describe "get_email/2" do
    test "when given id does not exist" do
      account = %Account{id: UUID.generate()}

      refute Service.get_email(%{id: UUID.generate()}, %{account: account})
    end

    test "when given id belongs to a different account" do
      account1 = account_fixture()
      account2 = account_fixture()
      email = email_fixture(account2)

      refute Service.get_email(%{id: email.id}, %{account: account1})
    end

    test "when given valid id" do
      account = account_fixture()
      email = email_fixture(account)

      assert Service.get_email(%{id: email.id}, %{account: account})
    end
  end

  describe "get_sms/2" do
    test "when given id does not exist" do
      account = %Account{id: UUID.generate()}

      refute Service.get_sms(%{id: UUID.generate()}, %{account: account})
    end

    test "when given id belongs to a different account" do
      account1 = account_fixture()
      account2 = account_fixture()
      sms = sms_fixture(account2)

      refute Service.get_sms(%{id: sms.id}, %{account: account1})
    end

    test "when given valid id" do
      account = account_fixture()
      sms = sms_fixture(account)

      assert Service.get_sms(%{id: sms.id}, %{account: account})
    end
  end

  describe "create_sms_template/2" do
    test "when given invalid fields" do
      account = %Account{id: UUID.generate()}

      {:error, %{errors: errors}} = Service.create_sms_template(%{}, %{account: account})

      assert match_keys(errors, [:name, :to, :body])
    end

    test "when given valid fields" do
      account = account_fixture()
      fields = %{
        "name" => Faker.Lorem.sentence(5),
        "to" => Faker.Phone.EnUs.phone,
        "body" => Faker.Lorem.sentence(5)
      }

      {:ok, sms_template} = Service.create_sms_template(fields, %{account: account})

      assert sms_template.name == fields["name"]
      assert sms_template.to == fields["to"]
      assert sms_template.body == fields["body"]
    end
  end

  describe "delete_sms_template/2" do
    test "when given identifiers has no match" do
      account = %Account{id: UUID.generate()}

      {:error, :not_found} =  Service.delete_sms_template(%{id: UUID.generate()}, %{account: account})
    end

    test "when given identifiers belongs to a different account" do
      account1 = account_fixture()
      account2 = account_fixture()
      sms_template = sms_template_fixture(account2)

      {:error, :not_found} = Service.delete_sms_template(%{id: sms_template.id}, %{account: account1})
    end

    test "when given valid identifiers" do
      account = account_fixture()
      sms_template = sms_template_fixture(account)

      {:ok, _} = Service.delete_sms_template(%{id: sms_template.id}, %{account: account})
    end
  end
end
