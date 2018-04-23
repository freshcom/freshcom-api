defmodule BlueJet.Notification do
  use BlueJet, :context

  alias BlueJet.Notification.Policy
  alias BlueJet.Notification.Service

  def list_email(request) do
    with {:ok, request} <- preprocess_request(request, "notification.list_email") do
      request
      |> do_list_email()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_email(request = %{ account: account, filter: filter }) do
    total_count =
      %{ filter: filter, search: request.search }
      |> Service.count_email(%{ account: account })

    all_count = Service.count_email(%{ account: account })

    emails =
      %{ filter: filter, search: request.search }
      |> Service.list_email(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

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

  def get_email(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "get_email") do
      do_get_email(authorized_args)
    else
      other -> other
    end
  end

  def do_get_email(args) do
    email = Service.get_email(args[:identifiers], args[:opts])

    if email do
      {:ok, %AccessResponse{ meta: %{ locale: args[:opts][:locale] }, data: email }}
    else
      {:error, :not_found}
    end
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

  def do_list_email_template(request = %{ account: account, filter: filter }) do
    total_count =
      %{ filter: filter, search: request.search }
      |> Service.count_email_template(%{ account: account })

    all_count = Service.count_email_template(%{ account: account })

    email_templates =
      %{ filter: filter, search: request.search }
      |> Service.list_email_template(get_sopts(request))
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

  def create_email_template(request) do
    with {:ok, request} <- preprocess_request(request, "notification.create_email_template") do
      request
      |> do_create_email_template()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_email_template(request = %{ account: account }) do
    with {:ok, email_template} <- Service.create_email_template(request.fields, get_sopts(request)) do
      email_template = Translation.translate(email_template, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: email_template }}
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
      %{ id: id }
      |> Service.get_email_template(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    if email_template do
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: email_template }}
    else
      {:error, :not_found}
    end
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
    with {:ok, email_template} <- Service.update_email_template(id, request.fields, get_sopts(request)) do
      email_template = Translation.translate(email_template, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: email_template }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
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
    with {:ok, _} <- Service.delete_email_template(id, %{ account: account }) do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  #
  # MARK: SMS
  #
  def list_sms(request) do
    with {:ok, request} <- preprocess_request(request, "notification.list_sms") do
      request
      |> do_list_sms()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_sms(request = %{ account: account, filter: filter }) do
    total_count =
      %{ filter: filter, search: request.search }
      |> Service.count_sms(%{ account: account })

    all_count = Service.count_sms(%{ account: account })

    smses =
      %{ filter: filter, search: request.search }
      |> Service.list_sms(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    response = %AccessResponse{
      meta: %{
        locale: request.locale,
        all_count: all_count,
        total_count: total_count
      },
      data: smses
    }

    {:ok, response}
  end

  def get_sms(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "get_sms") do
      do_get_sms(authorized_args)
    else
      other -> other
    end
  end

  def do_get_sms(args) do
    sms = Service.get_sms(args[:identifiers], args[:opts])

    if sms do
      {:ok, %AccessResponse{ meta: %{ locale: args[:opts][:locale] }, data: sms }}
    else
      {:error, :not_found}
    end
  end

  #
  # MARK: SMS Template
  #
  def list_sms_template(request) do
    with {:ok, request} <- preprocess_request(request, "notification.list_sms_template") do
      request
      |> do_list_sms_template()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_sms_template(request = %{ account: account, filter: filter }) do
    total_count =
      %{ filter: filter, search: request.search }
      |> Service.count_sms_template(%{ account: account })

    all_count = Service.count_sms_template(%{ account: account })

    sms_templates =
      %{ filter: filter, search: request.search }
      |> Service.list_sms_template(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    response = %AccessResponse{
      meta: %{
        locale: request.locale,
        all_count: all_count,
        total_count: total_count
      },
      data: sms_templates
    }

    {:ok, response}
  end

  def create_sms_template(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "create_sms_template") do
      do_create_sms_template(authorized_args)
    else
      other -> other
    end
  end

  def do_create_sms_template(args) do
    with {:ok, sms_template} <- Service.create_sms_template(args[:fields], args[:opts]) do
      locale = args[:opts][:locale]
      sms_template = Translation.translate(sms_template, locale, args[:opts][:account].default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: locale }, data: sms_template }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def get_sms_template(request) do
    with {:ok, request} <- preprocess_request(request, "notification.get_sms_template") do
      request
      |> do_get_sms_template()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_get_sms_template(request = %{ account: account, params: %{ "id" => id } }) do
    sms_template =
      %{ id: id }
      |> Service.get_sms_template(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    if sms_template do
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: sms_template }}
    else
      {:error, :not_found}
    end
  end

  def update_sms_template(request) do
    with {:ok, request} <- preprocess_request(request, "notification.update_sms_template") do
      request
      |> do_update_sms_template()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_update_sms_template(request = %{ account: account, params: %{ "id" => id } }) do
    with {:ok, sms_template} <- Service.update_sms_template(id, request.fields, get_sopts(request)) do
      sms_template = Translation.translate(sms_template, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: sms_template }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  #
  # MARK: Trigger
  #
  def list_trigger(request) do
    with {:ok, request} <- preprocess_request(request, "notification.list_trigger") do
      request
      |> do_list_trigger()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_trigger(request = %{ account: account, filter: filter }) do
    total_count =
      %{ filter: filter, search: request.search }
      |> Service.count_trigger(%{ account: account })

    all_count = Service.count_trigger(%{ account: account })

    triggers =
      %{ filter: filter, search: request.search }
      |> Service.list_trigger(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    response = %AccessResponse{
      meta: %{
        locale: request.locale,
        all_count: all_count,
        total_count: total_count
      },
      data: triggers
    }

    {:ok, response}
  end

  def create_trigger(request) do
    with {:ok, request} <- preprocess_request(request, "notification.create_trigger") do
      request
      |> do_create_trigger()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_trigger(request = %{ account: account }) do
    with {:ok, trigger} <- Service.create_trigger(request.fields, get_sopts(request)) do
      trigger = Translation.translate(trigger, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: trigger }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def get_trigger(request) do
    with {:ok, request} <- preprocess_request(request, "notification.get_trigger") do
      request
      |> do_get_trigger()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_get_trigger(request = %{ account: account, params: %{ "id" => id } }) do
    trigger =
      %{ id: id }
      |> Service.get_trigger(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    if trigger do
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: trigger }}
    else
      {:error, :not_found}
    end
  end

  def update_trigger(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "update_trigger") do
      do_update_trigger(authorized_args)
    else
      other -> other
    end
  end

  def do_update_trigger(args) do
    with {:ok, trigger} <- Service.update_trigger(args[:id], args[:fields], args[:opts]) do
      {:ok, %AccessResponse{ meta: %{ locale: args[:opts][:locale] }, data: trigger }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete_trigger(request) do
    with {:ok, request} <- preprocess_request(request, "notification.delete_trigger") do
      request
      |> do_delete_trigger()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_delete_trigger(%{ account: account, params: %{ "id" => id } }) do
    with {:ok, _} <- Service.delete_trigger(id, %{ account: account }) do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end
end
