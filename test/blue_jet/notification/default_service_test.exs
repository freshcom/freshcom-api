defmodule BlueJet.Notification.DefaultServiceTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity.Account

  alias BlueJet.Notification.{Trigger}
  alias BlueJet.Notification.DefaultService

  describe "update_trigger/2" do
    test "when given nil for trigger" do
      {:error, error} = DefaultService.update_trigger(nil, %{}, %{})

      assert error == :not_found
    end

    test "when given id does not exist" do
      account = Repo.insert!(%Account{})

      {:error, error} = DefaultService.update_trigger(Ecto.UUID.generate(), %{}, %{ account: account })

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

      {:error, error} = DefaultService.update_trigger(trigger.id, %{}, %{ account: account })

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

      {:ok, trigger} = DefaultService.update_trigger(trigger.id, fields, %{ account: account })

      assert trigger
    end
  end
end
