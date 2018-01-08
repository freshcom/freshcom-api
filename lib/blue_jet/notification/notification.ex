defmodule BlueJet.Notification do
  use BlueJet, :context

  alias BlueJet.Notification.Email
  alias BlueJet.Notification.EmailTemplate

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

end
