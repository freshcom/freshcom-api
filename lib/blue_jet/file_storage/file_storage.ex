defmodule BlueJet.FileStorage do
  use BlueJet, :context

  alias BlueJet.FileStorage.{Policy, Service}

  #
  # MARK: File
  #
  def list_file(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "list_file") do
      do_list_file(authorize_args)
    else
      other -> other
    end
  end

  def do_list_file(args) do
    total_count =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.count_file(args[:opts])

    all_count =
      %{ filter: args[:all_count_filter] }
      |> Service.count_file(args[:opts])

    files =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.list_file(args[:opts])
      |> Translation.translate(args[:locale], args[:default_locale])

    response = %AccessResponse{
      meta: %{
        locale: args[:locale],
        all_count: all_count,
        total_count: total_count
      },
      data: files
    }

    {:ok, response}
  end

  def create_file(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "create_file") do
      do_create_file(authorize_args)
    else
      other -> other
    end
  end

  def do_create_file(args) do
    with {:ok, file} <- Service.create_file(args[:fields], args[:opts]) do
      file = Translation.translate(file, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: file }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def get_file(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "get_file") do
      do_get_file(authorize_args)
    else
      other -> other
    end
  end

  def do_get_file(args) do
    file =
      Service.get_file(args[:identifiers], args[:opts])
      |> Translation.translate(args[:locale], args[:default_locale])

    if file do
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: file }}
    else
      {:error, :not_found}
    end
  end

  def update_file(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "update_file") do
      do_update_file(authorize_args)
    else
      other -> other
    end
  end

  def do_update_file(args) do
    with {:ok, file} <- Service.update_file(args[:id], args[:fields], args[:opts]) do
      file = Translation.translate(file, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: file }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete_file(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "delete_file") do
      do_delete_file(authorize_args)
    else
      other -> other
    end
  end

  def do_delete_file(args) do
    with {:ok, _} <- Service.delete_file(args[:id], args[:opts]) do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  #
  # MARK: File Collection
  #
  def list_file_collection(request) do
    with {:ok, request} <- preprocess_request(request, "file_storage.list_file_collection") do
      request
      |> do_list_file_collection()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_file_collection(request = %{ role: role, account: account, filter: filter }) when role in ["guest", "customer"] do
    total_count =
      %{ filter: filter, search: request.search }
      |> Service.count_file_collection(%{ account: account })

    all_count =
      %{ filter: %{ status: "active" } }
      |> Service.count_file_collection(%{ account: account })

    file_collections =
      %{ filter: filter, search: request.search }
      |> Service.list_file_collection(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    response = %AccessResponse{
      meta: %{
        locale: request.locale,
        all_count: all_count,
        total_count: total_count
      },
      data: file_collections
    }

    {:ok, response}
  end

  def do_list_file_collection(request = %{ account: account, filter: filter }) do
    total_count =
      %{ filter: filter, search: request.search }
      |> Service.count_file_collection(%{ account: account })

    all_count = Service.count_file_collection(%{ account: account })

    file_collections =
      %{ filter: filter, search: request.search }
      |> Service.list_file_collection(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    response = %AccessResponse{
      meta: %{
        locale: request.locale,
        all_count: all_count,
        total_count: total_count
      },
      data: file_collections
    }

    {:ok, response}
  end

  def create_file_collection(request) do
    with {:ok, request} <- preprocess_request(request, "file_storage.create_file_collection") do
      request
      |> do_create_file_collection()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_file_collection(request = %{ account: account }) do
    with {:ok, file_collection} <- Service.create_file_collection(request.fields, get_sopts(request)) do
      file_collection = Translation.translate(file_collection, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: file_collection }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def get_file_collection(request) do
    with {:ok, request} <- preprocess_request(request, "file_storage.get_file_collection") do
      request
      |> do_get_file_collection()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_get_file_collection(request = %{ account: account, params: %{ "id" => id } }) do
    file_collection =
      %{ id: id }
      |> Service.get_file_collection(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    if file_collection do
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: file_collection }}
    else
      {:error, :not_found}
    end
  end

  def update_file_collection(request) do
    with {:ok, request} <- preprocess_request(request, "file_storage.update_file_collection") do
      request
      |> do_update_file_collection()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_update_file_collection(request = %{ account: account, params: %{ "id" => id }}) do
    with {:ok, file_collection} <- Service.update_file_collection(id, request.fields, get_sopts(request)) do
      file_collection = Translation.translate(file_collection, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: file_collection }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  # TODO: use another process to delete, and also need to remove the files
  def delete_file_collection(request) do
    with {:ok, request} <- preprocess_request(request, "file_storage.delete_file_collection") do
      request
      |> do_delete_file_collection()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_delete_file_collection(%{ account: account, params: %{ "id" => id } }) do
    with {:ok, _} <- Service.delete_file_collection(id, %{ account: account }) do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  #
  # MARK: File Collection Membership
  #
  def create_file_collection_membership(request) do
    with {:ok, request} <- preprocess_request(request, "file_storage.create_file_collection_membership") do
      request
      |> do_create_file_collection_membership()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_file_collection_membership(request = %{
    account: account,
    params: %{ "collection_id" => collection_id }
  }) do
    fields = Map.merge(request.fields, %{ "collection_id" => collection_id })

    with {:ok, fcm} <- Service.create_file_collection_membership(fields, get_sopts(request)) do
      fcm = Translation.translate(fcm, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: fcm }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def update_file_collection_membership(request) do
    with {:ok, request} <- preprocess_request(request, "file_storage.update_file_collection_membership") do
      request
      |> do_update_file_collection_membership()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_update_file_collection_membership(request = %{ account: account, params: %{ "id" => id }}) do
    with {:ok, fcm} <- Service.update_file_collection_membership(id, request.fields, get_sopts(request)) do
      fcm = Translation.translate(fcm, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: fcm }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete_file_collection_membership(request) do
    with {:ok, request} <- preprocess_request(request, "file_storage.delete_file_collection_membership") do
      request
      |> do_delete_file_collection_membership()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_delete_file_collection_membership(%{ account: account, params: %{ "id" => id } }) do
    with {:ok, _} <- Service.delete_file_collection_membership(id, %{ account: account }) do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end
end
