defmodule BlueJet.Notification.TestHelper do
  alias BlueJet.Repo

  alias BlueJet.Notification.Service
  alias BlueJet.Notification.{Email, SMS}

  def trigger_fixture(account, fields \\ %{}) do
    default_fields = %{
      name: Faker.Lorem.sentence(5),
      event: Faker.Lorem.sentence(5),
      action_type: Enum.random(["send_email", "send_sms", "webhook"]),
      action_target: Faker.Lorem.sentence(5)
    }
    fields = Map.merge(default_fields, fields)

    {:ok, trigger} = Service.create_trigger(fields, %{account: account})

    trigger
  end

  def email_fixture(account) do
    Repo.insert!(%Email{
      account_id: account.id
    })
  end

  def sms_fixture(account) do
    Repo.insert!(%SMS{
      account_id: account.id
    })
  end

  def sms_template_fixture(account, fields \\ %{}) do
    default_fields = %{
      name: Faker.Lorem.sentence(5),
      body: Faker.Lorem.sentence(5),
      to: "+1234567890"
    }
    fields = Map.merge(default_fields, fields)

    {:ok, sms_template} = Service.create_sms_template(fields, %{account: account})

    sms_template
  end

  def email_template_fixture(account, fields \\ %{}) do
    default_fields = %{
      name: Faker.Lorem.sentence(5),
      to: "{{user.email}}",
      subject: Faker.Lorem.sentence(5),
      body_html: Faker.Lorem.sentence(5),
      body_text: Faker.Lorem.sentence(5)
    }
    fields = Map.merge(default_fields, fields)

    {:ok, email_template} = Service.create_email_template(fields, %{account: account})

    email_template
  end
end
