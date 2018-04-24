defmodule BlueJet.Notification.DefaultService do
  use BlueJet, :service

  alias Ecto.Multi
  alias BlueJet.Notification.IdentityService
  alias BlueJet.Notification.{Trigger, Email, EmailTemplate, Sms, SmsTemplate}

  @behaviour BlueJet.Notification.Service

  defp get_account(opts) do
    opts[:account] || IdentityService.get_account(opts)
  end

  defp put_account(opts) do
    Map.put(opts, :account, get_account(opts))
  end

  #
  # MARK: Trigger
  #
  def list_trigger(fields \\ %{}, opts) do
    account = get_account(opts)
    pagination = get_pagination(opts)
    preloads = get_preloads(opts, account)
    filter = get_filter(fields)

    Trigger.Query.default()
    |> Trigger.Query.search(fields[:search])
    |> Trigger.Query.filter_by(filter)
    |> Trigger.Query.for_account(account.id)
    |> Trigger.Query.paginate(size: pagination[:size], number: pagination[:number])
    |> Trigger.Query.order_by([desc: :updated_at])
    |> Repo.all()
    |> preload(preloads[:path], preloads[:opts])
  end

  def count_trigger(fields \\ %{}, opts) do
    account = get_account(opts)
    filter = get_filter(fields)

    Trigger.Query.default()
    |> Trigger.Query.search(fields[:search])
    |> Trigger.Query.filter_by(filter)
    |> Trigger.Query.for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def create_trigger(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %Trigger{ account_id: account.id, account: account }
      |> Trigger.changeset(:insert, fields)

    with {:ok, trigger} <- Repo.insert(changeset) do
      trigger = preload(trigger, preloads[:path], preloads[:opts])
      {:ok, trigger}
    else
      other -> other
    end
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

  def get_trigger(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    Trigger.Query.default()
    |> Trigger.Query.for_account(account.id)
    |> Repo.get_by(fields)
    |> preload(preloads[:path], preloads[:opts])
  end

  def update_trigger(nil, _, _), do: {:error, :not_found}

  def update_trigger(trigger = %Trigger{}, fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %{ trigger | account: account }
      |> Trigger.changeset(:update, fields)

    with {:ok, trigger} <- Repo.update(changeset) do
      trigger = preload(trigger, preloads[:path], preloads[:opts])
      {:ok, trigger}
    else
      other -> other
    end
  end

  def update_trigger(id, fields, opts) do
    opts = put_account(opts)
    account = opts[:account]

    Trigger
    |> Repo.get_by(id: id, account_id: account.id)
    |> update_trigger(fields, opts)
  end

  def delete_trigger(nil, _), do: {:error, :not_found}

  def delete_trigger(trigger = %Trigger{}, opts) do
    account = get_account(opts)

    changeset =
      %{ trigger | account: account }
      |> Trigger.changeset(:delete)

    with {:ok, trigger} <- Repo.delete(changeset) do
      {:ok, trigger}
    else
      other -> other
    end
  end

  def delete_trigger(id, opts) do
    opts = put_account(opts)
    account = opts[:account]

    Trigger
    |> Repo.get_by(id: id, account_id: account.id)
    |> delete_trigger(opts)
  end

  def delete_all_trigger(opts = %{ account: account = %{ mode: "test" } }) do
    batch_size = opts[:batch_size] || 1000

    trigger_ids =
      Trigger.Query.default()
      |> Trigger.Query.for_account(account.id)
      |> Trigger.Query.paginate(size: batch_size, number: 1)
      |> Trigger.Query.id_only()
      |> Repo.all()

    Trigger.Query.default()
    |> Trigger.Query.filter_by(%{ id: trigger_ids })
    |> Repo.delete_all()

    if length(trigger_ids) === batch_size do
      delete_all_trigger(opts)
    else
      :ok
    end
  end

  #
  # MARK: List Email
  #
  def list_email(fields \\ %{}, opts) do
    account = get_account(opts)
    pagination = get_pagination(opts)
    preloads = get_preloads(opts, account)
    filter = get_filter(fields)

    Email.Query.default()
    |> Email.Query.search(fields[:search])
    |> Email.Query.filter_by(filter)
    |> Email.Query.for_account(account.id)
    |> Email.Query.paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> preload(preloads[:path], preloads[:opts])
  end

  def count_email(fields \\ %{}, opts) do
    account = get_account(opts)
    filter = get_filter(fields)

    Email.Query.default()
    |> Email.Query.search(fields[:search])
    |> Email.Query.filter_by(filter)
    |> Email.Query.for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def delete_all_email(opts = %{ account: account = %{ mode: "test" } }) do
    batch_size = opts[:batch_size] || 1000

    email_ids =
      Email.Query.default()
      |> Email.Query.for_account(account.id)
      |> Email.Query.paginate(size: batch_size, number: 1)
      |> Email.Query.id_only()
      |> Repo.all()

    Email.Query.default()
    |> Email.Query.filter_by(%{ id: email_ids })
    |> Repo.delete_all()

    if length(email_ids) === batch_size do
      delete_all_email(opts)
    else
      :ok
    end
  end

  def get_email(identifiers, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    Email.Query.default()
    |> Email.Query.for_account(account.id)
    |> Repo.get_by(identifiers)
    |> preload(preloads[:path], preloads[:opts])
  end

  #
  # MARK: Email Template
  #
  def list_email_template(fields \\ %{}, opts) do
    account = get_account(opts)
    pagination = get_pagination(opts)
    preloads = get_preloads(opts, account)
    filter = get_filter(fields)

    EmailTemplate.Query.default()
    |> EmailTemplate.Query.search(fields[:search], opts[:locale], account.default_locale)
    |> EmailTemplate.Query.filter_by(filter)
    |> EmailTemplate.Query.for_account(account.id)
    |> EmailTemplate.Query.paginate(size: pagination[:size], number: pagination[:number])
    |> EmailTemplate.Query.order_by([desc: :updated_at])
    |> Repo.all()
    |> preload(preloads[:path], preloads[:opts])
  end

  def count_email_template(fields \\ %{}, opts) do
    account = get_account(opts)
    filter = get_filter(fields)

    EmailTemplate.Query.default()
    |> EmailTemplate.Query.search(fields[:search], opts[:locale], account.default_locale)
    |> EmailTemplate.Query.filter_by(filter)
    |> EmailTemplate.Query.for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def create_email_template(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %EmailTemplate{ account_id: account.id, account: account }
      |> EmailTemplate.changeset(:insert, fields)

    with {:ok, email_template} <- Repo.insert(changeset) do
      email_template = preload(email_template, preloads[:path], preloads[:opts])
      {:ok, email_template}
    else
      other -> other
    end
  end

  def get_email_template(identifiers, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    EmailTemplate.Query.default()
    |> EmailTemplate.Query.for_account(account.id)
    |> Repo.get_by(identifiers)
    |> preload(preloads[:path], preloads[:opts])
  end

  def update_email_template(nil, _, _), do: {:error, :not_found}

  def update_email_template(email_template = %EmailTemplate{}, fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %{ email_template | account: account }
      |> EmailTemplate.changeset(:update, fields, opts[:locale])

    statements =
      Multi.new()
      |> Multi.update(:email_template, changeset)

    case Repo.transaction(statements) do
      {:ok, %{ email_template: email_template }} ->
        email_template = preload(email_template, preloads[:path], preloads[:opts])
        {:ok, email_template}

      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  def update_email_template(id, fields, opts) do
    opts = put_account(opts)
    account = opts[:account]

    EmailTemplate
    |> Repo.get_by(id: id, account_id: account.id)
    |> update_email_template(fields, opts)
  end

  def delete_email_template(nil, _), do: {:error, :not_found}

  def delete_email_template(email_template = %EmailTemplate{}, opts) do
    account = get_account(opts)

    changeset =
      %{ email_template | account: account }
      |> EmailTemplate.changeset(:delete)

    with {:ok, email_template} <- Repo.delete(changeset) do
      {:ok, email_template}
    else
      other -> other
    end
  end

  def delete_email_template(id, opts) do
    opts = put_account(opts)
    account = opts[:account]

    EmailTemplate
    |> Repo.get_by(id: id, account_id: account.id)
    |> delete_email_template(opts)
  end

  def delete_all_email_template(opts = %{ account: account = %{ mode: "test" } }) do
    batch_size = opts[:batch_size] || 1000

    email_template_ids =
      EmailTemplate.Query.default()
      |> EmailTemplate.Query.for_account(account.id)
      |> EmailTemplate.Query.paginate(size: batch_size, number: 1)
      |> EmailTemplate.Query.id_only()
      |> Repo.all()

    EmailTemplate.Query.default()
    |> EmailTemplate.Query.filter_by(%{ id: email_template_ids })
    |> Repo.delete_all()

    if length(email_template_ids) === batch_size do
      delete_all_email_template(opts)
    else
      :ok
    end
  end

  #
  # MARK: List SMS
  #
  def list_sms(fields \\ %{}, opts) do
    account = get_account(opts)
    pagination = get_pagination(opts)
    preloads = get_preloads(opts, account)
    filter = get_filter(fields)

    Sms.Query.default()
    |> Sms.Query.search(fields[:search])
    |> Sms.Query.filter_by(filter)
    |> Sms.Query.for_account(account.id)
    |> Sms.Query.paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> preload(preloads[:path], preloads[:opts])
  end

  def count_sms(fields \\ %{}, opts) do
    account = get_account(opts)
    filter = get_filter(fields)

    Sms.Query.default()
    |> Sms.Query.search(fields[:search])
    |> Sms.Query.filter_by(filter)
    |> Sms.Query.for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def get_sms(identifiers, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    Sms.Query.default()
    |> Sms.Query.for_account(account.id)
    |> Repo.get_by(identifiers)
    |> preload(preloads[:path], preloads[:opts])
  end

  def delete_all_sms(opts = %{ account: account = %{ mode: "test" } }) do
    batch_size = opts[:batch_size] || 1000

    sms_ids =
      Sms.Query.default()
      |> Sms.Query.for_account(account.id)
      |> Sms.Query.paginate(size: batch_size, number: 1)
      |> Sms.Query.id_only()
      |> Repo.all()

    Sms.Query.default()
    |> Sms.Query.filter_by(%{ id: sms_ids })
    |> Repo.delete_all()

    if length(sms_ids) === batch_size do
      delete_all_sms(opts)
    else
      :ok
    end
  end

  #
  # MARK: SMS Template
  #
  def list_sms_template(fields \\ %{}, opts) do
    account = get_account(opts)
    pagination = get_pagination(opts)
    preloads = get_preloads(opts, account)

    SmsTemplate.Query.default()
    |> SmsTemplate.Query.search(fields[:search], opts[:locale], account.default_locale)
    |> SmsTemplate.Query.for_account(account.id)
    |> SmsTemplate.Query.paginate(size: pagination[:size], number: pagination[:number])
    |> SmsTemplate.Query.order_by([desc: :updated_at])
    |> Repo.all()
    |> preload(preloads[:path], preloads[:opts])
  end

  def count_sms_template(fields \\ %{}, opts) do
    account = get_account(opts)

    SmsTemplate.Query.default()
    |> SmsTemplate.Query.search(fields[:search], opts[:locale], account.default_locale)
    |> SmsTemplate.Query.for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def create_sms_template(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %SmsTemplate{ account_id: account.id, account: account }
      |> SmsTemplate.changeset(:insert, fields)

    with {:ok, sms_template} <- Repo.insert(changeset) do
      sms_template = preload(sms_template, preloads[:path], preloads[:opts])
      {:ok, sms_template}
    else
      other -> other
    end
  end

  def get_sms_template(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    SmsTemplate.Query.default()
    |> SmsTemplate.Query.for_account(account.id)
    |> Repo.get_by(fields)
    |> preload(preloads[:path], preloads[:opts])
  end

  def update_sms_template(nil, _, _), do: {:error, :not_found}

  def update_sms_template(sms_template = %SmsTemplate{}, fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %{ sms_template | account: account }
      |> SmsTemplate.changeset(:update, fields, opts[:locale])

    statements =
      Multi.new()
      |> Multi.update(:sms_template, changeset)

    case Repo.transaction(statements) do
      {:ok, %{ sms_template: sms_template }} ->
        sms_template = preload(sms_template, preloads[:path], preloads[:opts])
        {:ok, sms_template}

      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  def update_sms_template(id, fields, opts) do
    opts = put_account(opts)
    account = opts[:account]

    SmsTemplate
    |> Repo.get_by(id: id, account_id: account.id)
    |> update_sms_template(fields, opts)
  end

  def delete_sms_template(nil, _), do: {:error, :not_found}

  def delete_sms_template(sms_template = %SmsTemplate{}, opts) do
    account = get_account(opts)

    changeset =
      %{ sms_template | account: account }
      |> SmsTemplate.changeset(:delete)

    with {:ok, sms_template} <- Repo.delete(changeset) do
      {:ok, sms_template}
    else
      other -> other
    end
  end

  def delete_sms_template(identifiers, opts) do
    opts = put_account(opts)
    account = opts[:account]
    identifiers = Map.put(identifiers, :account_id, account.id)

    SmsTemplate
    |> Repo.get_by(identifiers)
    |> delete_sms_template(opts)
  end

  def delete_all_sms_template(opts = %{ account: account = %{ mode: "test" } }) do
    batch_size = opts[:batch_size] || 1000

    sms_template_ids =
      SmsTemplate.Query.default()
      |> SmsTemplate.Query.for_account(account.id)
      |> SmsTemplate.Query.paginate(size: batch_size, number: 1)
      |> SmsTemplate.Query.id_only()
      |> Repo.all()

    SmsTemplate.Query.default()
    |> SmsTemplate.Query.filter_by(%{ id: sms_template_ids })
    |> Repo.delete_all()

    if length(sms_template_ids) === batch_size do
      delete_all_sms_template(opts)
    else
      :ok
    end
  end
end