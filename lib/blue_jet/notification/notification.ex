defmodule BlueJet.Notification do
  use BlueJet, :context

  alias BlueJet.GlobalMailer

  alias BlueJet.Notification.NotificationTrigger
  alias BlueJet.Notification.Email
  alias BlueJet.Notification.EmailTemplate

  # Creates the default email template and notification trigger for account when
  # an account is first created.
  def handle_event("identity.account.created", %{ account: account, test_account: test_account }) do
    # Live account
    template =
      account
      |> EmailTemplate.AccountDefault.password_reset()
      |> Repo.insert!()
    account
    |> NotificationTrigger.AccountDefault.send_password_reset_email(template)
    |> Repo.insert!()

    template =
      account
      |> EmailTemplate.AccountDefault.email_confirmation()
      |> Repo.insert!()
    account
    |> NotificationTrigger.AccountDefault.send_email_confirmation_email(template)
    |> Repo.insert!()

    # Test account
    template =
      test_account
      |> EmailTemplate.AccountDefault.password_reset()
      |> Repo.insert!()
    test_account
    |> NotificationTrigger.AccountDefault.send_password_reset_email(template)
    |> Repo.insert!()
    template =
      test_account
      |> EmailTemplate.AccountDefault.email_confirmation()
      |> Repo.insert!()
    test_account
    |> NotificationTrigger.AccountDefault.send_email_confirmation_email(template)
    |> Repo.insert!()

    {:ok, nil}
  end

  def handle_event("identity.password_reset_token.created", %{ account: nil, user: user, email: email }) do
    case user do
      nil ->
        Email.Factory.password_reset_not_registered_email(email)
        |> GlobalMailer.deliver_later()

      _ ->
        Email.Factory.password_reset_email(user)
        |> GlobalMailer.deliver_later()
    end
  end

  def handle_event(event, data = %{ account: account }) when not is_nil(account) do
    triggers =
      NotificationTrigger.Query.default()
      |> NotificationTrigger.Query.for_account(account.id)
      |> NotificationTrigger.Query.for_event(event)
      |> Repo.all()

    Enum.each(triggers, fn(trigger) ->
      NotificationTrigger.process(trigger, data)
    end)

    {:ok, nil}
  end

  def handle_event(_, _) do
    {:ok, nil}
  end

  def list_email(request) do
    with {:ok, request} <- preprocess_request(request, "notification.list_email") do
      request
      |> do_list_email()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_email(request = %{ account: account, filter: filter, pagination: pagination }) do
    data_query =
      Email.Query.default()
      |> search([:to, :subject], request.search)
      |> filter_by(status: filter[:status])
      |> Email.Query.for_account(account.id)

    total_count = Repo.aggregate(data_query, :count, :id)
    all_count =
      Email.Query.default()
      |> filter_by(status: filter[:status])
      |> Email.Query.for_account(account.id)
      |> Repo.aggregate(:count, :id)

    preloads = Email.Query.preloads(request.preloads, role: request.role)
    emails =
      data_query
      |> paginate(size: pagination[:size], number: pagination[:number])
      |> Repo.all()
      |> Repo.preload(preloads)

    response = %AccessResponse{
      meta: %{
        locale: request.locale,
        all_count: all_count,
        total_count: total_count
      },
      data: emails
    }

    {:ok, response}
  end

  #
  # MARK: Email Templates
  #
  def list_email_template(request) do
    with {:ok, request} <- preprocess_request(request, "notification.list_email_template") do
      request
      |> do_list_email_template()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_email_template(request = %{ account: account, filter: filter, pagination: pagination }) do
    data_query =
      EmailTemplate.Query.default()
      |> search([:name], request.search, request.locale, account.default_locale)
      |> filter_by(status: filter[:status])
      |> EmailTemplate.Query.for_account(account.id)

    total_count = Repo.aggregate(data_query, :count, :id)
    all_count =
      EmailTemplate.Query.default()
      |> filter_by(status: filter[:status])
      |> EmailTemplate.Query.for_account(account.id)
      |> Repo.aggregate(:count, :id)

    preloads = EmailTemplate.Query.preloads(request.preloads, role: request.role)
    email_templates =
      data_query
      |> paginate(size: pagination[:size], number: pagination[:number])
      |> Repo.all()
      |> Repo.preload(preloads)
      |> Translation.translate(request.locale, account.default_locale)

    response = %AccessResponse{
      meta: %{
        locale: request.locale,
        all_count: all_count,
        total_count: total_count
      },
      data: email_templates
    }

    {:ok, response}
  end

  defp email_template_response(nil, _), do: {:error, :not_found}

  defp email_template_response(email_template, request = %{ account: account }) do
    preloads = EmailTemplate.Query.preloads(request.preloads, role: request.role)

    email_template =
      email_template
      |> Repo.preload(preloads)
      |> Translation.translate(request.locale, account.default_locale)

    {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: email_template }}
  end

  def create_email_template(request) do
    with {:ok, request} <- preprocess_request(request, "notification.create_email_template") do
      request
      |> do_create_email_template()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_email_template(request = %{ account: account }) do
    changeset = EmailTemplate.changeset(%EmailTemplate{ account_id: account.id}, request.fields, request.locale, account.default_locale)

    with {:ok, email_template} <- Repo.insert(changeset) do
      email_template_response(email_template, request)
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def get_email_template(request) do
    with {:ok, request} <- preprocess_request(request, "notification.get_email_template") do
      request
      |> do_get_email_template()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_get_email_template(request = %{ account: account, params: %{ "id" => id } }) do
    email_template =
      EmailTemplate.Query.default()
      |> EmailTemplate.Query.for_account(account.id)
      |> Repo.get(id)

    email_template_response(email_template, request)
  end

  def update_email_template(request) do
    with {:ok, request} <- preprocess_request(request, "notification.update_email_template") do
      request
      |> do_update_email_template()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_update_email_template(request = %{ account: account, params: %{ "id" => id } }) do
    email_template =
      EmailTemplate.Query.default()
      |> EmailTemplate.Query.for_account(account.id)
      |> Repo.get(id)

    with %EmailTemplate{} <- email_template,
         changeset <- EmailTemplate.changeset(email_template, request.fields, request.locale, account.default_locale),
         {:ok, email_template} <- Repo.update(changeset)
    do
      email_template_response(email_template, request)
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      nil ->
        {:error, :not_found}
    end
  end

  def delete_email_template(request) do
    with {:ok, request} <- preprocess_request(request, "notification.delete_email_template") do
      request
      |> do_delete_email_template()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_delete_email_template(%{ account: account, params: %{ "id" => id } }) do
    email_template =
      EmailTemplate.Query.default()
      |> EmailTemplate.Query.for_account(account.id)
      |> Repo.get(id)

    if email_template do
      Repo.delete!(email_template)
      {:ok, %AccessResponse{}}
    else
      {:error, :not_found}
    end
  end


  #
  # MARK: Trigger
  #
  def list_notification_trigger(request) do
    with {:ok, request} <- preprocess_request(request, "notification.list_notification_trigger") do
      request
      |> do_list_notification_trigger()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_notification_trigger(request = %{ account: account, filter: filter, pagination: pagination }) do
    data_query =
      NotificationTrigger.Query.default()
      |> search([:name], request.search)
      |> filter_by(status: filter[:status])
      |> NotificationTrigger.Query.for_account(account.id)

    total_count = Repo.aggregate(data_query, :count, :id)
    all_count =
      NotificationTrigger.Query.default()
      |> filter_by(status: filter[:status])
      |> NotificationTrigger.Query.for_account(account.id)
      |> Repo.aggregate(:count, :id)

    preloads = NotificationTrigger.Query.preloads(request.preloads, role: request.role)
    notification_triggers =
      data_query
      |> paginate(size: pagination[:size], number: pagination[:number])
      |> Repo.all()
      |> Repo.preload(preloads)

    response = %AccessResponse{
      meta: %{
        locale: request.locale,
        all_count: all_count,
        total_count: total_count
      },
      data: notification_triggers
    }

    {:ok, response}
  end

  defp notification_trigger_response(nil, _), do: {:error, :not_found}

  defp notification_trigger_response(notification_trigger, request) do
    preloads = NotificationTrigger.Query.preloads(request.preloads, role: request.role)

    notification_trigger =
      notification_trigger
      |> Repo.preload(preloads)

    {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: notification_trigger }}
  end

  def create_notification_trigger(request) do
    with {:ok, request} <- preprocess_request(request, "notification.create_notification_trigger") do
      request
      |> do_create_notification_trigger()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_notification_trigger(request = %{ account: account }) do
    changeset = NotificationTrigger.changeset(%NotificationTrigger{ account_id: account.id }, request.fields)

    with {:ok, notification_trigger} <- Repo.insert(changeset) do
      notification_trigger_response(notification_trigger, request)
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end
end
