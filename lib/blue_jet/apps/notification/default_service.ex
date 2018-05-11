defmodule BlueJet.Notification.DefaultService do
  use BlueJet, :service

  alias BlueJet.Notification.{Trigger, Email, EmailTemplate, Sms, SmsTemplate}

  @behaviour BlueJet.Notification.Service

  #
  # MARK: Trigger
  #
  def list_trigger(fields \\ %{}, opts) do
    list(Trigger, fields, opts)
  end

  def count_trigger(fields \\ %{}, opts) do
    count(Trigger, fields, opts)
  end

  def create_trigger(fields, opts) do
    create(Trigger, fields, opts)
  end

  def create_system_default_trigger(%{ account: account }) do
    # Password Reset
    email_template =
      account
      |> EmailTemplate.AccountDefault.password_reset()
      |> Repo.insert!()
    account
    |> Trigger.AccountDefault.send_password_reset_email(email_template)
    |> Repo.insert!()

    email_template =
      account
      |> EmailTemplate.AccountDefault.password_reset_not_registered()
      |> Repo.insert!()
    account
    |> Trigger.AccountDefault.send_password_reset_not_registered_email(email_template)
    |> Repo.insert!()

    # Email Verification
    email_template =
      account
      |> EmailTemplate.AccountDefault.email_verification()
      |> Repo.insert!()
    account
    |> Trigger.AccountDefault.send_email_verification_email(email_template)
    |> Repo.insert!()

    # Order Confirmation
    email_template =
      account
      |> EmailTemplate.AccountDefault.order_confirmation()
      |> Repo.insert!()
    account
    |> Trigger.AccountDefault.send_order_confirmation_email(email_template)
    |> Repo.insert!()

    # Phone Verification Code
    sms_template =
      account
      |> SmsTemplate.AccountDefault.phone_verification_code()
      |> Repo.insert!()
    account
    |> Trigger.AccountDefault.send_phone_verification_code_sms(sms_template)
    |> Repo.insert!()

    # TFA CODE
    sms_template =
      account
      |> SmsTemplate.AccountDefault.tfa_code()
      |> Repo.insert!()
    account
    |> Trigger.AccountDefault.send_tfa_code_sms(sms_template)
    |> Repo.insert!()

    :ok
  end

  def get_trigger(identifiers, opts) do
    get(Trigger, identifiers, opts)
  end

  def update_trigger(nil, _, _), do: {:error, :not_found}

  def update_trigger(trigger = %Trigger{}, fields, opts) do
    update(trigger, fields, opts)
  end

  def update_trigger(identifiers, fields, opts) do
    get_trigger(identifiers, Map.merge(opts, %{ preloads: %{} }))
    |> update_trigger(fields, opts)
  end

  def delete_trigger(nil, _), do: {:error, :not_found}

  def delete_trigger(trigger = %Trigger{}, opts) do
    delete(trigger, opts)
  end

  def delete_trigger(identifiers, opts) do
    get_trigger(identifiers, Map.merge(opts, %{ preloads: %{} }))
    |> delete_trigger(opts)
  end

  def delete_all_trigger(opts) do
    delete_all(Trigger, opts)
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
    get_email_template(identifiers, Map.merge(opts, %{ preloads: %{} }))
    |> update_email_template(fields, opts)
  end

  def delete_email_template(nil, _), do: {:error, :not_found}

  def delete_email_template(email_template = %EmailTemplate{}, opts) do
    delete(email_template, opts)
  end

  def delete_email_template(identifiers, opts) do
    get_email_template(identifiers, Map.merge(opts, %{ preloads: %{} }))
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
    get_sms_template(identifiers, Map.merge(opts, %{ preloads: %{} }))
    |> update_sms_template(fields, opts)
  end

  def delete_sms_template(nil, _), do: {:error, :not_found}

  def delete_sms_template(sms_template = %SmsTemplate{}, opts) do
    delete(sms_template, opts)
  end

  def delete_sms_template(identifiers, opts) do
    get_sms_template(identifiers, Map.merge(opts, %{ preloads: %{} }))
    |> delete_sms_template(opts)
  end

  def delete_all_sms_template(opts) do
    delete_all(SmsTemplate, opts)
  end
end