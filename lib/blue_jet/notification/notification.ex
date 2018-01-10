defmodule BlueJet.Notification do
  use BlueJet, :context

  alias BlueJet.Notification.NotificationTrigger
  alias BlueJet.Notification.Email
  alias BlueJet.Notification.EmailTemplate

  def handle_event(event_id, data = %{ account: account }) when not is_nil(account) do
    triggers =
      NotificationTrigger.Query.default()
      |> NotificationTrigger.Query.for_account(account.id)
      |> NotificationTrigger.Query.for_event(event_id)
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
      |> search([:recipient_email], request.search)
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
      |> search([:name], request.search)
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

  defp email_template_response(email_template, request) do
    preloads = EmailTemplate.Query.preloads(request.preloads, role: request.role)

    email_template =
      email_template
      |> Repo.preload(preloads)

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
    changeset = EmailTemplate.changeset(%EmailTemplate{ account_id: account.id}, request.fields)

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
         changeset <- EmailTemplate.changeset(email_template, request.fields),
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
end
