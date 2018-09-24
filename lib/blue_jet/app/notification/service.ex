defmodule BlueJet.Notification.Service do
  use BlueJet, :service

  alias BlueJet.Notification.{Trigger, Email, EmailTemplate, Sms, SmsTemplate}

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

  # def create_system_default_trigger(%{account: account}) do
  #   # Password Reset
  #   email_template =
  #     account
  #     |> EmailTemplate.Factory.password_reset()
  #     |> Repo.insert!()

  #   account
  #   |> Trigger.Factory.send_password_reset_email(email_template)
  #   |> Repo.insert!()

  #   email_template =
  #     account
  #     |> EmailTemplate.Factory.password_reset_not_registered()
  #     |> Repo.insert!()

  #   account
  #   |> Trigger.Factory.send_password_reset_not_registered_email(email_template)
  #   |> Repo.insert!()

  #   # Email Verification
  #   email_template =
  #     account
  #     |> EmailTemplate.Factory.email_verification()
  #     |> Repo.insert!()

  #   account
  #   |> Trigger.Factory.send_email_verification_email(email_template)
  #   |> Repo.insert!()

  #   # Order Confirmation
  #   email_template =
  #     account
  #     |> EmailTemplate.Factory.order_confirmation()
  #     |> Repo.insert!()

  #   account
  #   |> Trigger.Factory.send_order_confirmation_email(email_template)
  #   |> Repo.insert!()

  #   # Phone Verification Code
  #   sms_template =
  #     account
  #     |> SmsTemplate.AccountDefault.phone_verification_code()
  #     |> Repo.insert!()

  #   account
  #   |> Trigger.Factory.send_phone_verification_code_sms(sms_template)
  #   |> Repo.insert!()

  #   # TFA CODE
  #   sms_template =
  #     account
  #     |> SmsTemplate.AccountDefault.tfa_code()
  #     |> Repo.insert!()

  #   account
  #   |> Trigger.Factory.send_tfa_code_sms(sms_template)
  #   |> Repo.insert!()

  #   :ok
  # end

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
    template = SmsTemplate.Factory.phone_verification(account)

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
    template = SmsTemplate.Factory.tfa(account)

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
  def list_email(fields \\ %{}, opts) do
    list(Email, fields, opts)
  end

  def count_email(fields \\ %{}, opts) do
    count(Email, fields, opts)
  end

  def get_email(identifiers, opts) do
    get(Email, identifiers, opts)
  end

  def delete_all_email(opts) do
    delete_all(Email, opts)
  end

  #
  # MARK: Email Template
  #
  def list_email_template(fields \\ %{}, opts) do
    list(EmailTemplate, fields, opts)
  end

  def count_email_template(fields \\ %{}, opts) do
    count(EmailTemplate, fields, opts)
  end

  def create_email_template(fields, opts) do
    create(EmailTemplate, fields, opts)
  end

  def get_email_template(identifiers, opts) do
    get(EmailTemplate, identifiers, opts)
  end

  def update_email_template(nil, _, _), do: {:error, :not_found}

  def update_email_template(email_template = %EmailTemplate{}, fields, opts) do
    update(email_template, fields, opts)
  end

  def update_email_template(identifiers, fields, opts) do
    get_email_template(identifiers, Map.merge(opts, %{preloads: %{}}))
    |> update_email_template(fields, opts)
  end

  def delete_email_template(nil, _), do: {:error, :not_found}

  def delete_email_template(email_template = %EmailTemplate{}, opts) do
    delete(email_template, opts)
  end

  def delete_email_template(identifiers, opts) do
    get_email_template(identifiers, Map.merge(opts, %{preloads: %{}}))
    |> delete_email_template(opts)
  end

  def delete_all_email_template(opts) do
    delete_all(EmailTemplate, opts)
  end

  #
  # MARK: List SMS
  #
  def list_sms(fields \\ %{}, opts) do
    list(Sms, fields, opts)
  end

  def count_sms(fields \\ %{}, opts) do
    count(Sms, fields, opts)
  end

  def get_sms(identifiers, opts) do
    get(Sms, identifiers, opts)
  end

  def delete_all_sms(opts) do
    delete_all(Sms, opts)
  end

  #
  # MARK: SMS Template
  #
  def list_sms_template(fields \\ %{}, opts) do
    list(SmsTemplate, fields, opts)
  end

  def count_sms_template(fields \\ %{}, opts) do
    count(SmsTemplate, fields, opts)
  end

  def create_sms_template(fields, opts) do
    create(SmsTemplate, fields, opts)
  end

  def get_sms_template(identifiers, opts) do
    get(SmsTemplate, identifiers, opts)
  end

  def update_sms_template(nil, _, _), do: {:error, :not_found}

  def update_sms_template(sms_template = %SmsTemplate{}, fields, opts) do
    update(sms_template, fields, opts)
  end

  def update_sms_template(identifiers, fields, opts) do
    get_sms_template(identifiers, Map.merge(opts, %{preloads: %{}}))
    |> update_sms_template(fields, opts)
  end

  def delete_sms_template(nil, _), do: {:error, :not_found}

  def delete_sms_template(sms_template = %SmsTemplate{}, opts) do
    delete(sms_template, opts)
  end

  def delete_sms_template(identifiers, opts) do
    get_sms_template(identifiers, Map.merge(opts, %{preloads: %{}}))
    |> delete_sms_template(opts)
  end

  def delete_all_sms_template(opts) do
    delete_all(SmsTemplate, opts)
  end
end
