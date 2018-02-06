defmodule BlueJet.FileStorage do
  use BlueJet, :context

  alias BlueJet.FileStorage
  alias BlueJet.FileStorage.Service

  ####
  # Macro
  ####
  defmodule Macro do
    def put_external_resources_ef(field) do
      foreign_key = String.to_atom(Atom.to_string(field) <> "_id")

      quote do
        def put_external_resources(resource = %{ unquote(foreign_key) => nil }, {unquote(field), nil}, _), do: resource

        def put_external_resources(resource = %{ unquote(foreign_key) => ef_id }, {unquote(field), nil}, %{ account: account, locale: locale }) do
          {:ok, %{ data: ef }} = FileStorage.do_get_file(%AccessRequest{
            account: account,
            params: %{ "id" => ef_id },
            locale: locale
          })

          Map.put(resource, unquote(field), ef)
        end
      end
    end

    def put_external_resources_efc(field, owner_type) do
      quote do
        def put_external_resources(resource, {unquote(field), efc_preloads}, %{ account: account, role: role, locale: locale }) do
          request = %AccessRequest{
            account: account,
            filter: %{ owner_id: resource.id, owner_type: unquote(owner_type) },
            pagination: %{ size: 5, number: 1 },
            preloads: listify(efc_preloads),
            role: role,
            locale: locale
          }

          {:ok, %{ data: efcs }} =
            request
            |> AccessRequest.transform_by_role()
            |> FileStorage.do_list_file_collection()

          Map.put(resource, unquote(field), efcs)
        end
      end
    end

    defmacro __using__(put_external_resources: :file, field: field) do
      put_external_resources_ef(field)
    end

    defmacro __using__(put_external_resources: :file_collection, field: field, owner_type: owner_type) do
      put_external_resources_efc(field, owner_type)
    end
  end

  #
  # MARK: File
  #
  def list_file(request) do
    with {:ok, request} <- preprocess_request(request, "file_storage.list_file") do
      request
      |> do_list_file
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_file(request = %{ account: account, filter: filter }) do
    total_count =
      %{ filter: filter, search: request.search }
      |> Service.count_file(%{ account: account })

    all_count = Service.count_file(%{ account: account })

    files =
      %{ filter: filter, search: request.search }
      |> Service.list_file(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    response = %AccessResponse{
      meta: %{
        locale: request.locale,
        all_count: all_count,
        total_count: total_count
      },
      data: files
    }

    {:ok, response}
  end

  def create_file(request) do
    with {:ok, request} <- preprocess_request(request, "file_storage.create_file") do
      request
      |> do_create_file()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_file(request = %{ vas: vas, account: account }) do
    fields = Map.merge(request.fields, %{ "user_id" => vas[:user_id] })

    with {:ok, file} <- Service.create_file(fields, get_sopts(request)) do
      file = Translation.translate(file, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: file }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def get_file(request) do
    with {:ok, request} <- preprocess_request(request, "file_storage.get_file") do
      request
      |> do_get_file()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_get_file(request = %{ account: account, params: %{ "id" => id }}) do
    file =
      %{ id: id }
      |> Service.get_file(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    if file do
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: file }}
    else
      {:error, :not_found}
    end
  end

  def update_file(request) do
    with {:ok, request} <- preprocess_request(request, "file_storage.update_file") do
      request
      |> do_update_file()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_update_file(request = %{ account: account, params: %{ "id" => id }}) do
    with {:ok, file} <- Service.update_file(id, request.fields, get_sopts(request)) do
      file = Translation.translate(file, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: file }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete_file(request) do
    with {:ok, request} <- preprocess_request(request, "file_storage.delete_file") do
      request
      |> do_delete_file()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_delete_file(%{ account: account, params: %{ "id" => id } }) do
    with {:ok, _} <- Service.delete_file(id, %{ account: account }) do
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
