defmodule BlueJet.Notification.EventHandler do
  @behaviour BlueJet.EventHandler

  import BlueJet.Query

  alias BlueJet.Repo
  alias BlueJet.Notification.Service
  alias BlueJet.GlobalMailer
  alias BlueJet.Notification.{Trigger, Email}

  @account_reset "identity:account.reset.success"
  @account_created "identity:account.create.success"

  def handle_event(@account_reset, %{account: account = %{mode: "test"}}) do
    Task.start(fn ->
      Service.delete_all_trigger(%{account: account})
      Service.delete_all_email_template(%{account: account})
      Service.delete_all_email(%{account: account})
      Service.delete_all_sms(%{account: account})
      Service.delete_all_sms_template(%{account: account})

      Service.create_default_triggers(%{account: account})
    end)

    {:ok, nil}
  end

  # Creates the default email template and notification trigger for account when
  # an account is first created.
  def handle_event(@account_created, %{account: account}) do
    Repo.transaction(fn ->
      Service.create_default_triggers(%{account: account})
      Service.create_default_triggers(%{account: account.test_account})
    end)

    {:ok, nil}
  end

  # Standard user should not use account trigger
  def handle_event("identity:email_verification_token.create.success", %{user: %{account_id: nil}}) do
    {:ok, nil}
  end

  def handle_event("identity:password_reset_token.create.success", %{
        user: %{account_id: nil} = user
      }) do
    Email.Factory.password_reset_email(user)
    |> GlobalMailer.deliver_later()

    {:ok, nil}
  end

  def handle_event("identity:password_reset_token.create.error.username_not_found", %{
        email: email,
        account_id: nil
      }) do
    Email.Factory.password_reset_not_registered_email(email)
    |> GlobalMailer.deliver_later()

    {:ok, nil}
  end

  def handle_event(event, data = %{account: account}) when not is_nil(account) do
    triggers =
      Trigger.Query.default()
      |> for_account(account.id)
      |> Trigger.Query.filter_by(%{event: event})
      |> Repo.all()

    Enum.each(triggers, fn trigger ->
      Trigger.fire_action(trigger, data)
    end)

    {:ok, nil}
  end

  def handle_event(_, _) do
    {:ok, nil}
  end
end
