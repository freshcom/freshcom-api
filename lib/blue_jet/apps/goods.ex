defmodule BlueJet.Goods do
  use BlueJet, :context

  alias BlueJet.Goods.{Policy, Service}

  #
  # MARK: Stockable
  #
  def list_stockable(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "list_stockable") do
      do_list_stockable(authorized_args)
    else
      other -> other
    end
  end

  def do_list_stockable(args) do
    total_count =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.count_stockable(args[:opts])

    all_count =
      %{ filter: args[:all_count_filter] }
      |> Service.count_stockable(args[:opts])

    stockables =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.list_stockable(args[:opts])
      |> Translation.translate(args[:locale], args[:default_locale])

    response = %AccessResponse{
      meta: %{
        locale: args[:locale],
        all_count: all_count,
        total_count: total_count
      },
      data: stockables
    }

    {:ok, response}
  end

  def create_stockable(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "create_stockable") do
      do_create_stockable(authorized_args)
    else
      other -> other
    end
  end

  def do_create_stockable(args) do
    with {:ok, stockable} <- Service.create_stockable(args[:fields], args[:opts]) do
      stockable = Translation.translate(stockable, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: stockable }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def get_stockable(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "get_stockable") do
      do_get_stockable(authorized_args)
    else
      other -> other
    end
  end

  def do_get_stockable(args) do
    stockable =
      Service.get_stockable(args[:identifiers], args[:opts])
      |> Translation.translate(args[:locale], args[:default_locale])

    if stockable do
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: stockable }}
    else
      {:error, :not_found}
    end
  end

  def update_stockable(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "update_stockable") do
      do_update_stockable(authorized_args)
    else
      other -> other
    end
  end

  def do_update_stockable(args) do
    with {:ok, stockable} <- Service.update_stockable(args[:identifiers], args[:fields], args[:opts]) do
      stockable = Translation.translate(stockable, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: stockable }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete_stockable(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "delete_stockable") do
      do_delete_stockable(authorized_args)
    else
      other -> other
    end
  end

  def do_delete_stockable(args) do
    with {:ok, _} <- Service.delete_stockable(args[:identifiers], args[:opts]) do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  #
  # MARK: Unlockable
  #
  def list_unlockable(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "list_unlockable") do
      do_list_unlockable(authorized_args)
    else
      other -> other
    end
  end

  def do_list_unlockable(args) do
    total_count =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.count_unlockable(args[:opts])

    all_count =
      %{ filter: args[:all_count_filter] }
      |> Service.count_unlockable(args[:opts])

    unlockables =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.list_unlockable(args[:opts])
      |> Translation.translate(args[:locale], args[:default_locale])

    response = %AccessResponse{
      meta: %{
        locale: args[:locale],
        all_count: all_count,
        total_count: total_count
      },
      data: unlockables
    }

    {:ok, response}
  end

  def create_unlockable(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "create_unlockable") do
      do_create_unlockable(authorized_args)
    else
      other -> other
    end
  end

  def do_create_unlockable(args) do
    with {:ok, unlockable} <- Service.create_unlockable(args[:fields], args[:opts]) do
      unlockable = Translation.translate(unlockable, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: unlockable }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def get_unlockable(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "get_unlockable") do
      do_get_unlockable(authorized_args)
    else
      other -> other
    end
  end

  def do_get_unlockable(args) do
    unlockable =
      Service.get_unlockable(args[:identifiers], args[:opts])
      |> Translation.translate(args[:locale], args[:default_locale])

    if unlockable do
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: unlockable }}
    else
      {:error, :not_found}
    end
  end

  def update_unlockable(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "update_unlockable") do
      do_update_unlockable(authorized_args)
    else
      other -> other
    end
  end

  def do_update_unlockable(args) do
    with {:ok, unlockable} <- Service.update_unlockable(args[:identifiers], args[:fields], args[:opts]) do
      unlockable = Translation.translate(unlockable, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: unlockable }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete_unlockable(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "delete_unlockable") do
      do_delete_unlockable(authorized_args)
    else
      other -> other
    end
  end

  def do_delete_unlockable(args) do
    with {:ok, _} <- Service.delete_unlockable(args[:identifiers], args[:opts]) do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  #
  # MARK: Depositable
  #
  def list_depositable(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "list_depositable") do
      do_list_depositable(authorized_args)
    else
      other -> other
    end
  end

  def do_list_depositable(args) do
    total_count =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.count_depositable(args[:opts])

    all_count =
      %{ filter: args[:all_count_filter] }
      |> Service.count_depositable(args[:opts])

    depositables =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.list_depositable(args[:opts])
      |> Translation.translate(args[:locale], args[:default_locale])

    response = %AccessResponse{
      meta: %{
        locale: args[:locale],
        all_count: all_count,
        total_count: total_count
      },
      data: depositables
    }

    {:ok, response}
  end

  def create_depositable(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "create_depositable") do
      do_create_depositable(authorized_args)
    else
      other -> other
    end
  end

  def do_create_depositable(args) do
    with {:ok, depositable} <- Service.create_depositable(args[:fields], args[:opts]) do
      depositable = Translation.translate(depositable, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: depositable }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def get_depositable(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "get_depositable") do
      do_get_depositable(authorized_args)
    else
      other -> other
    end
  end

  def do_get_depositable(args) do
    depositable =
      Service.get_depositable(args[:identifiers], args[:opts])
      |> Translation.translate(args[:locale], args[:default_locale])

    if depositable do
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: depositable }}
    else
      {:error, :not_found}
    end
  end

  def update_depositable(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "update_depositable") do
      do_update_depositable(authorized_args)
    else
      other -> other
    end
  end

  def do_update_depositable(args) do
    with {:ok, depositable} <- Service.update_depositable(args[:identifiers], args[:fields], args[:opts]) do
      depositable = Translation.translate(depositable, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: depositable }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete_depositable(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "delete_depositable") do
      do_delete_depositable(authorized_args)
    else
      other -> other
    end
  end

  def do_delete_depositable(args) do
    with {:ok, _} <- Service.delete_depositable(args[:identifiers], args[:opts]) do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end
end
