defmodule BlueJet.Fulfillment do
  use BlueJet, :context

  alias BlueJet.Fulfillment.{Policy, Service}

  #
  # MARK: Fulfillment Package
  #
  def list_fulfillment_package(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "list_fulfillment_package") do
      do_list_fulfillment_package(authorized_args)
    else
      other -> other
    end
  end

  def do_list_fulfillment_package(args) do
    total_count =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.count_fulfillment_package(args[:opts])

    all_count =
      %{ filter: args[:all_count_filter] }
      |> Service.count_fulfillment_package(args[:opts])

    fulfillment_packages =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.list_fulfillment_package(args[:opts])
      |> Translation.translate(args[:locale], args[:default_locale])

    response = %AccessResponse{
      meta: %{
        locale: args[:locale],
        all_count: all_count,
        total_count: total_count,
      },
      data: fulfillment_packages
    }

    {:ok, response}
  end

  def get_fulfillment_package(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "get_fulfillment_package") do
      do_get_fulfillment_package(authorized_args)
    else
      other -> other
    end
  end

  def do_get_fulfillment_package(args) do
    fulfillment_package = Service.get_fulfillment_package(args[:identifiers], args[:opts])

    if fulfillment_package do
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: fulfillment_package }}
    else
      {:error, :not_found}
    end
  end

  def delete_fulfillment_package(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "delete_fulfillment_package") do
      do_delete_fulfillment_package(authorized_args)
    else
      other -> other
    end
  end

  def do_delete_fulfillment_package(args) do
    with {:ok, _} <- Service.delete_fulfillment_package(args[:id], args[:opts]) do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  #
  # MARK: Fulfillment Item
  #
  def list_fulfillment_item(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "list_fulfillment_item") do
      do_list_fulfillment_item(authorized_args)
    else
      other -> other
    end
  end

  def do_list_fulfillment_item(args) do
    total_count =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.count_fulfillment_item(args[:opts])

    all_count =
      %{ filter: args[:all_count_filter] }
      |> Service.count_fulfillment_item(args[:opts])

    fulfillment_items =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.list_fulfillment_item(args[:opts])
      |> Translation.translate(args[:locale], args[:default_locale])

    response = %AccessResponse{
      meta: %{
        locale: args[:locale],
        all_count: all_count,
        total_count: total_count
      },
      data: fulfillment_items
    }

    {:ok, response}
  end

  def create_fulfillment_item(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "create_fulfillment_item") do
      do_create_fulfillment_item(authorized_args)
    else
      other -> other
    end
  end

  def do_create_fulfillment_item(args) do
    with {:ok, fulfillment_item} <- Service.create_fulfillment_item(args[:fields], args[:opts]) do
      fulfillment_item = Translation.translate(fulfillment_item, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: fulfillment_item }}
    else
      {:error, changeset} ->
        {:error, %AccessResponse{ errors: changeset.errors }}

      other -> other
    end
  end

  def update_fulfillment_item(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "update_fulfillment_item") do
      do_update_fulfillment_item(authorized_args)
    else
      other -> other
    end
  end

  def do_update_fulfillment_item(args) do
    with {:ok, fulfillment_item} <- Service.update_fulfillment_item(args[:id], args[:fields], args[:opts]) do
      fulfillment_item = Translation.translate(fulfillment_item, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: fulfillment_item }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  #
  # MARK: Return Package
  #
  def list_return_package(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "list_return_package") do
      do_list_return_package(authorized_args)
    else
      other -> other
    end
  end

  def do_list_return_package(args) do
    total_count =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.count_return_package(args[:opts])

    all_count =
      %{ filter: args[:all_count_filter] }
      |> Service.count_return_package(args[:opts])

    return_packages =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.list_return_package(args[:opts])
      |> Translation.translate(args[:locale], args[:default_locale])

    response = %AccessResponse{
      meta: %{
        locale: args[:locale],
        all_count: all_count,
        total_count: total_count,
      },
      data: return_packages
    }

    {:ok, response}
  end

  #
  # MARK: Return Item
  #
  def create_return_item(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "create_return_item") do
      do_create_return_item(authorized_args)
    else
      other -> other
    end
  end

  def do_create_return_item(args) do
    with {:ok, return_item} <- Service.create_return_item(args[:fields], args[:opts]) do
      return_item = Translation.translate(return_item, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: return_item }}
    else
      {:error, changeset} ->
        {:error, %AccessResponse{ errors: changeset.errors }}

      other -> other
    end
  end

  #
  # MARK: Unlock
  #
  def list_unlock(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "list_unlock") do
      do_list_unlock(authorized_args)
    else
      other -> other
    end
  end

  def do_list_unlock(args) do
    total_count = Service.count_unlock(%{ filter: args[:filter] }, args[:opts])
    all_count = Service.count_unlock(%{ filter: args[:all_count_filter] }, args[:opts])

    unlocks =
      Service.list_unlock(%{ filter: args[:filter] }, args[:opts])
      |> Translation.translate(args[:locale], args[:default_locale])

    response = %AccessResponse{
      meta: %{
        locale: args[:locale],
        all_count: all_count,
        total_count: total_count
      },
      data: unlocks
    }

    {:ok, response}
  end

  def create_unlock(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "create_unlock") do
      do_create_unlock(authorized_args)
    else
      other -> other
    end
  end

  def do_create_unlock(args) do
    with {:ok, unlock} <- Service.create_unlock(args[:fields], args[:opts]) do
      unlock = Translation.translate(unlock, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: unlock }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def get_unlock(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "get_unlock") do
      do_get_unlock(authorized_args)
    else
      other -> other
    end
  end

  def do_get_unlock(args) do
    unlock =
      Service.get_unlock(args[:identifiers], args[:opts])
      |> Translation.translate(args[:locale], args[:default_locale])

    if unlock do
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: unlock }}
    else
      {:error, :not_found}
    end
  end

  def delete_unlock(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "delete_unlock") do
      do_delete_unlock(authorized_args)
    else
      other -> other
    end
  end

  def do_delete_unlock(args) do
    with {:ok, _} <- Service.delete_unlock(args[:id], args[:opts]) do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end
end