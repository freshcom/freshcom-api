defmodule BlueJet.Notification.Service do
  use BlueJet, :service

  alias BlueJet.Notification.{Trigger, Email, EmailTemplate, SMS, SMSTemplate}

  #
  # MARK: Trigger
  #
  def list_trigger(query \\ %{}, opts), do: default_list(Trigger.Query, query, opts)
  def count_trigger(query \\ %{}, opts), do: default_count(Trigger.Query, query, opts)
  def create_trigger(fields, opts), do: default_create(Trigger, fields, opts)
  def get_trigger(identifiers, opts), do: default_get(Trigger.Query, identifiers, opts)
  def update_trigger(%Trigger{} = trigger, fields, opts), do: default_update(trigger, fields, opts)
  def update_trigger(identifiers, fields, opts), do: default_update(identifiers, fields, opts, &get_trigger/2)
  def delete_trigger(%Trigger{} = trigger, opts), do: default_delete(trigger, opts)
  def delete_trigger(identifiers, opts), do: default_delete(identifiers, opts, &get_trigger/2)
  def delete_all_trigger(opts), do: default_delete_all(Trigger.Query, opts)

  def create_default_triggers(%{account: account}) do
    statements =
      Multi.new()
      |> Multi.run(:_1, fn(_) -> create_password_reset_trigger(account) end)
      |> Multi.run(:_2, fn(_) -> create_email_verification_trigger(account) end)
      |> Multi.run(:_3, fn(_) -> create_order_confirmation_trigger(account) end)
      |> Multi.run(:_4, fn(_) -> create_phone_verification_trigger(account) end)
      |> Multi.run(:_5, fn(_) -> create_tfa_trigger(account) end)

    {:ok, _} = Repo.transaction(statements)

    :ok
  end

  defp create_password_reset_trigger(account) do
    pr_template = EmailTemplate.Factory.password_reset(account)
    prnr_template = EmailTemplate.Factory.password_reset_not_registered(account)

    statements =
      Multi.new()
      |> Multi.insert(:pr_template, pr_template)
      |> Multi.insert(:prnr_template, prnr_template)
      |> Multi.run(:pr_trigger, fn(%{pr_template: pr_template}) ->
        trigger =
          account
          |> Trigger.Factory.send_password_reset_email(pr_template)
          |> Repo.insert!()

        {:ok, trigger}
      end)
      |> Multi.run(:prnr_trigger, fn(%{prnr_template: prnr_template}) ->
        trigger =
          account
          |> Trigger.Factory.send_password_reset_not_registered_email(prnr_template)
          |> Repo.insert!()

        {:ok, trigger}
      end)

    {:ok, _} = Repo.transaction(statements)

    {:ok, nil}
  end

  defp create_email_verification_trigger(account) do
    template = EmailTemplate.Factory.email_verification(account)

    statements =
      Multi.new()
      |> Multi.insert(:template, template)
      |> Multi.run(:trigger, fn(%{template: template}) ->
        trigger =
          account
          |> Trigger.Factory.send_email_verification_email(template)
          |> Repo.insert!()

        {:ok, trigger}
      end)

    {:ok, _} = Repo.transaction(statements)

    {:ok, nil}
  end

  defp create_order_confirmation_trigger(account) do
    template = EmailTemplate.Factory.order_confirmation(account)

    statements =
      Multi.new()
      |> Multi.insert(:template, template)
      |> Multi.run(:trigger, fn(%{template: template}) ->
        trigger =
          account
          |> Trigger.Factory.send_order_confirmation_email(template)
          |> Repo.insert!()

        {:ok, trigger}
      end)

    {:ok, _} = Repo.transaction(statements)

    {:ok, nil}
  end

  defp create_phone_verification_trigger(account) do
    template = SMSTemplate.Factory.phone_verification(account)

    statements =
      Multi.new()
      |> Multi.insert(:template, template)
      |> Multi.run(:trigger, fn(%{template: template}) ->
        trigger =
          account
          |> Trigger.Factory.send_phone_verification_sms(template)
          |> Repo.insert!()

        {:ok, trigger}
      end)

    {:ok, _} = Repo.transaction(statements)

    {:ok, nil}
  end

  defp create_tfa_trigger(account) do
    template = SMSTemplate.Factory.tfa(account)

    statements =
      Multi.new()
      |> Multi.insert(:template, template)
      |> Multi.run(:trigger, fn(%{template: template}) ->
        trigger =
          account
          |> Trigger.Factory.send_tfa_sms(template)
          |> Repo.insert!()

        {:ok, trigger}
      end)

    {:ok, _} = Repo.transaction(statements)

    {:ok, nil}
  end

  #
  # MARK: List Email
  #
  def list_email(query \\ %{}, opts), do: default_list(Email.Query, query, opts)
  def count_email(query \\ %{}, opts), do: default_count(Email.Query, query, opts)
  def get_email(identifiers, opts), do: default_get(Email.Query, identifiers, opts)
  def delete_all_email(opts), do: default_delete_all(Email.Query, opts)

  #
  # MARK: Email Template
  #
  def list_email_template(query \\ %{}, opts), do: default_list(EmailTemplate.Query, query, opts)
  def count_email_template(query \\ %{}, opts), do: default_count(EmailTemplate.Query, query, opts)
  def create_email_template(fields, opts), do: default_create(EmailTemplate, fields, opts)
  def get_email_template(identifiers, opts), do: default_get(EmailTemplate.Query, identifiers, opts)
  def update_email_template(%EmailTemplate{} = email_template, fields, opts), do: default_update(email_template, fields, opts)
  def update_email_template(identifiers, fields, opts), do: default_update(identifiers, fields, opts, &get_email_template/2)
  def delete_email_template(%EmailTemplate{} = email_template, opts), do: default_delete(email_template, opts)
  def delete_email_template(identifiers, opts), do: default_delete(identifiers, opts, &get_email_template/2)
  def delete_all_email_template(opts), do: default_delete_all(EmailTemplate.Query, opts)

  #
  # MARK: SMS
  #
  def list_sms(query \\ %{}, opts), do: default_list(SMS.Query, query, opts)
  def count_sms(query \\ %{}, opts), do: default_count(SMS.Query, query, opts)
  def get_sms(identifiers, opts), do: default_get(SMS.Query, identifiers, opts)
  def delete_all_sms(opts), do: default_delete_all(SMS.Query, opts)

  #
  # MARK: SMS Template
  #
  def list_sms_template(query \\ %{}, opts), do: default_list(SMSTemplate.Query, query, opts)
  def count_sms_template(query \\ %{}, opts), do: default_count(SMSTemplate.Query, query, opts)
  def create_sms_template(fields, opts), do: default_create(SMSTemplate, fields, opts)
  def get_sms_template(identifiers, opts), do: default_get(SMSTemplate.Query, identifiers, opts)
  def update_sms_template(%SMSTemplate{} = sms_template, fields, opts), do: default_update(sms_template, fields, opts)
  def update_sms_template(identifiers, fields, opts), do: default_update(identifiers, fields, opts, &get_sms_template/2)
  def delete_sms_template(%SMSTemplate{} = sms_template, opts), do: default_delete(sms_template, opts)
  def delete_sms_template(identifiers, opts), do: default_delete(identifiers, opts, &get_sms_template/2)
  def delete_all_sms_template(opts), do: default_delete_all(SMSTemplate.Query, opts)
end
