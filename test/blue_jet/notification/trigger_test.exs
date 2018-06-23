defmodule BlueJet.Notification.TriggerTest do
  use BlueJet.DataCase

  alias BlueJet.Identity.Account
  alias BlueJet.Notification.Trigger

  describe "schema" do
    test "when account is deleted trigger should be automatically deleted" do
      account = Repo.insert!(%Account{})
      trigger = Repo.insert!(%Trigger{
        account_id: account.id,
        name: Faker.Lorem.sentence(5),
        event: "test",
        action_type: "webhook",
        action_target: Faker.Internet.url()
      })
      Repo.delete!(account)

      refute Repo.get(Trigger, trigger.id)
    end
  end

  test "writable_fields/0" do
    assert Trigger.writable_fields() == [
      :status,
      :name,
      :event,
      :description,
      :action_target,
      :action_type
    ]
  end
end
