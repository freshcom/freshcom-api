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
    with {:ok, authorize_args} <- Policy.authorize(request, "list_file_collection") do
      do_list_file_collection(authorize_args)
    else
      other -> other
    end
  end

  def do_list_file_collection(args) do
    total_count =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.count_file_collection(args[:opts])

    all_count =
      %{ filter: args[:all_count_filter] }
      |> Service.count_file_collection(args[:opts])

    file_collections =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.list_file_collection(args[:opts])
      |> Translation.translate(args[:locale], args[:default_locale])

    response = %AccessResponse{
      meta: %{
        locale: args[:locale],
        all_count: all_count,
        total_count: total_count
      },
      data: file_collections
    }

    {:ok, response}
  end

  def create_file_collection(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "create_file_collection") do
      do_create_file_collection(authorize_args)
    else
      other -> other
    end
  end

  def do_create_file_collection(args) do
    with {:ok, file_collection} <- Service.create_file_collection(args[:fields], args[:opts]) do
      file_collection = Translation.translate(file_collection, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: file_collection }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def get_file_collection(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "get_file_collection") do
      do_get_file_collection(authorize_args)
    else
      other -> other
    end
  end

  def do_get_file_collection(args) do
    file_collection =
      Service.get_file_collection(args[:identifiers], args[:opts])
      |> Translation.translate(args[:locale], args[:default_locale])

    if file_collection do
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: file_collection }}
    else
      {:error, :not_found}
    end
  end

  def update_file_collection(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "update_file_collection") do
      do_update_file_collection(authorize_args)
    else
      other -> other
    end
  end

  def do_update_file_collection(args) do
    with {:ok, file_collection} <- Service.update_file_collection(args[:id], args[:fields], args[:opts]) do
      file_collection = Translation.translate(file_collection, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: file_collection }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  # TODO: use another process to delete, and also need to remove the files
  def delete_file_collection(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "delete_file_collection") do
      do_delete_file_collection(authorize_args)
    else
      other -> other
    end
  end

  def do_delete_file_collection(args) do
    with {:ok, _} <- Service.delete_file_collection(args[:id], args[:opts]) do
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
    with {:ok, authorize_args} <- Policy.authorize(request, "create_file_collection_membership") do
      do_create_file_collection_membership(authorize_args)
    else
      other -> other
    end
  end

  def do_create_file_collection_membership(args) do
    with {:ok, fcm} <- Service.create_file_collection_membership(args[:fields], args[:opts]) do
      fcm = Translation.translate(fcm, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: fcm }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def update_file_collection_membership(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "update_file_collection_membership") do
      do_update_file_collection_membership(authorize_args)
    else
      other -> other
    end
  end

  def do_update_file_collection_membership(args) do
    with {:ok, fcm} <- Service.update_file_collection_membership(args[:id], args[:fields], args[:opts]) do
      fcm = Translation.translate(fcm, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: fcm }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete_file_collection_membership(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "delete_file_collection_membership") do
      do_delete_file_collection_membership(authorize_args)
    else
      other -> other
    end
  end

  def do_delete_file_collection_membership(args) do
    with {:ok, _} <- Service.delete_file_collection_membership(args[:id], args[:opts]) do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end
end
