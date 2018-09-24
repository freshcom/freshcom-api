defmodule BlueJet.Notification.ServiceTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity.Account

  alias BlueJet.Notification.Service
  alias BlueJet.Notification.{Trigger, Email, Sms, SmsTemplate}

  describe "update_trigger/2" do
    test "when given id does not exist" do
      account = Repo.insert!(%Account{})

      {:error, error} = Service.update_trigger(%{ id: Ecto.UUID.generate() }, %{}, %{ account: account })

      assert error == :not_found
    end

    test "when given id belongs to a different account" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})

      trigger = Repo.insert!(%Trigger{
        account_id: other_account.id,
        name: Faker.Lorem.sentence(5),
        event: "test",
        action_type: "webhook",
        action_target: Faker.Internet.url()
      })

      {:error, error} = Service.update_trigger(%{ id: trigger.id }, %{}, %{ account: account })

      assert error == :not_found
    end

    test "when given valid id and valid fields" do
      account = Repo.insert!(%Account{})
      trigger = Repo.insert!(%Trigger{
        account_id: account.id,
        name: Faker.Lorem.sentence(5),
        event: "test",
        action_type: "webhook",
        action_target: Faker.Internet.url()
      })

      fields = %{
        "name" => Faker.Lorem.sentence(5)
      }

      {:ok, trigger} = Service.update_trigger(%{ id: trigger.id }, fields, %{ account: account })

      assert trigger
    end
  end

  describe "get_email/2" do
    test "when given identifiers has no match" do
      account = Repo.insert!(%Account{})

      refute Service.get_email(%{ id: Ecto.UUID.generate() }, %{ account: account })
    end

    test "when given identifiers belongs to a different account" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      email = Repo.insert!(%Email{
        account_id: other_account.id
      })

      refute Service.get_email(%{ id: email.id }, %{ account: account })
    end

    test "when given valid identifiers" do
      account = Repo.insert!(%Account{})
      email = Repo.insert!(%Email{
        account_id: account.id
      })

      assert Service.get_email(%{ id: email.id }, %{ account: account })
    end
  end

  describe "get_sms/2" do
    test "when given identifiers has no match" do
      account = Repo.insert!(%Account{})

      refute Service.get_sms(%{ id: Ecto.UUID.generate() }, %{ account: account })
    end

    test "when given identifiers belongs to a different account" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      sms = Repo.insert!(%Sms{
        account_id: other_account.id
      })

      refute Service.get_sms(%{ id: sms.id }, %{ account: account })
    end

    test "when given valid identifiers" do
      account = Repo.insert!(%Account{})
      sms = Repo.insert!(%Sms{
        account_id: account.id
      })

      assert Service.get_sms(%{ id: sms.id }, %{ account: account })
    end
  end

  describe "create_sms_template/2" do
    test "when given invalid fields" do
      account = Repo.insert!(%Account{})

      {:error, _} = Service.create_sms_template(%{}, %{ account: account })
    end

    test "when given valid fields" do
      account = Repo.insert!(%Account{})
      fields = %{
        "name" => Faker.Lorem.sentence(5),
        "to" => Faker.Phone.EnUs.phone,
        "body" => Faker.Lorem.sentence(5)
      }

      {:ok, _} = Service.create_sms_template(fields, %{ account: account })
    end
  end

  describe "delete_sms_template/2" do
    test "when given identifiers has no match" do
      account = Repo.insert!(%Account{})

      {:error, :not_found} =  Service.delete_sms_template(%{ id: Ecto.UUID.generate() }, %{ account: account })
    end

    test "when given identifiers belongs to a different account" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      sms_template = Repo.insert!(%SmsTemplate{
        account_id: other_account.id,
        name: Faker.Lorem.sentence(5)
      })

      {:error, :not_found} = Service.delete_sms_template(%{ id: sms_template.id }, %{ account: account })
    end

    test "when given valid identifiers" do
      account = Repo.insert!(%Account{})
      sms_template = Repo.insert!(%SmsTemplate{
        account_id: account.id,
        name: Faker.Lorem.sentence(5)
      })

      {:ok, _} = Service.delete_sms_template(%{ id: sms_template.id }, %{ account: account })
    end
  end
end
