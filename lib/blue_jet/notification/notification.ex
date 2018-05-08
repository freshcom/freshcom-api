defmodule BlueJet.Notification do
  use BlueJet, :context

  alias BlueJet.Notification.{Policy, Service}

  def list_email(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "list_email") do
      do_list_email(authorized_args)
    else
      other -> other
    end
  end

  def do_list_email(args) do
    total_count =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.count_email(args[:opts])

    all_count = Service.count_email(args[:opts])

    emails =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.list_email(args[:opts])
      |> Translation.translate(args[:locale], args[:default_locale])

    response = %AccessResponse{
      meta: %{
        locale: args[:locale],
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
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: email }}
    else
      {:error, :not_found}
    end
  end

  #
  # MARK: Email Templates
  #
  def list_email_template(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "list_email_template") do
      do_list_email_template(authorized_args)
    else
      other -> other
    end
  end

  def do_list_email_template(args) do
    total_count =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.count_email_template(args[:opts])

    all_count = Service.count_email_template(args[:opts])

    email_templates =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.list_email_template(args[:opts])
      |> Translation.translate(args[:locale], args[:default_locale])

    response = %AccessResponse{
      meta: %{
        locale: args[:locale],
        all_count: all_count,
        total_count: total_count
      },
      data: email_templates
    }

    {:ok, response}
  end

  def create_email_template(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "create_email_template") do
      do_create_email_template(authorized_args)
    else
      other -> other
    end
  end

  def do_create_email_template(args) do
    with {:ok, email_template} <- Service.create_email_template(args[:fields], args[:opts]) do
      email_template = Translation.translate(email_template, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: email_template }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def get_email_template(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "get_email_template") do
      do_get_email_template(authorized_args)
    else
      other -> other
    end
  end

  def do_get_email_template(args) do
    email_template =
      Service.get_email_template(args[:identifiers], args[:opts])
      |> Translation.translate(args[:locale], args[:default_locale])

    if email_template do
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: email_template }}
    else
      {:error, :not_found}
    end
  end

  def update_email_template(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "update_email_template") do
      do_update_email_template(authorized_args)
    else
      other -> other
    end
  end

  def do_update_email_template(args) do
    with {:ok, email_template} <- Service.update_email_template(args[:id], args[:fields], args[:opts]) do
      email_template = Translation.translate(email_template, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: email_template }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete_email_template(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "delete_email_template") do
      do_delete_email_template(authorized_args)
    else
      other -> other
    end
  end

  def do_delete_email_template(args) do
    with {:ok, _} <- Service.delete_email_template(args[:id], args[:opts]) do
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
    with {:ok, authorized_args} <- Policy.authorize(request, "list_sms") do
      do_list_sms(authorized_args)
    else
      other -> other
    end
  end

  def do_list_sms(args) do
    total_count =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.count_sms(args[:opts])

    all_count = Service.count_sms(args[:opts])

    smses =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.list_sms(args[:opts])
      |> Translation.translate(args[:locale], args[:default_locale])

    response = %AccessResponse{
      meta: %{
        locale: args[:locale],
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
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: sms }}
    else
      {:error, :not_found}
    end
  end

  #
  # MARK: SMS Template
  #
  def list_sms_template(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "list_sms_template") do
      do_list_sms_template(authorized_args)
    else
      other -> other
    end
  end

  def do_list_sms_template(args) do
    total_count =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.count_sms_template(args[:opts])

    all_count = Service.count_sms_template(args[:opts])

    sms_templates =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.list_sms_template(args[:opts])
      |> Translation.translate(args[:locale], args[:default_locale])

    response = %AccessResponse{
      meta: %{
        locale: args[:locale],
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
      sms_template = Translation.translate(sms_template, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: sms_template }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def get_sms_template(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "get_sms_template") do
      do_get_sms_template(authorized_args)
    else
      other -> other
    end
  end

  def do_get_sms_template(args) do
    sms_template =
      Service.get_sms_template(args[:identifiers], args[:opts])
      |> Translation.translate(args[:locale], args[:default_locale])

    if sms_template do
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: sms_template }}
    else
      {:error, :not_found}
    end
  end

  def update_sms_template(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "update_sms_template") do
      do_update_sms_template(authorized_args)
    else
      other -> other
    end
  end

  def do_update_sms_template(args) do
    with {:ok, sms_template} <- Service.update_sms_template(args[:id], args[:fields], args[:opts]) do
      sms_template = Translation.translate(sms_template, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: sms_template }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete_sms_template(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "delete_sms_template") do
      do_delete_sms_template(authorized_args)
    else
      other -> other
    end
  end

  def do_delete_sms_template(args) do
    with {:ok, _} <- Service.delete_sms_template(args[:id], args[:opts]) do
      {:ok, %AccessResponse{}}
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
    with {:ok, authorized_args} <- Policy.authorize(request, "list_trigger") do
      do_list_trigger(authorized_args)
    else
      other -> other
    end
  end

  def do_list_trigger(args) do
    total_count =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.count_trigger(args[:opts])

    all_count = Service.count_trigger(args[:opts])

    triggers =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.list_trigger(args[:opts])
      |> Translation.translate(args[:locale], args[:default_locale])

    response = %AccessResponse{
      meta: %{
        locale: args[:locale],
        all_count: all_count,
        total_count: total_count
      },
      data: triggers
    }

    {:ok, response}
  end

  def create_trigger(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "create_trigger") do
      do_create_trigger(authorized_args)
    else
      other -> other
    end
  end

  def do_create_trigger(args) do
    with {:ok, trigger} <- Service.create_trigger(args[:fields], args[:opts]) do
      trigger = Translation.translate(trigger, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: trigger }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def get_trigger(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "get_trigger") do
      do_get_trigger(authorized_args)
    else
      other -> other
    end
  end

  def do_get_trigger(args) do
    trigger =
      Service.get_trigger(args[:identifiers], args[:opts])
      |> Translation.translate(args[:locale], args[:default_locale])

    if trigger do
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: trigger }}
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
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: trigger }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete_trigger(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "delete_trigger") do
      do_delete_trigger(authorized_args)
    else
      other -> other
    end
  end

  def do_delete_trigger(args) do
    with {:ok, _} <- Service.delete_trigger(args[:id], args[:opts]) do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end
end
