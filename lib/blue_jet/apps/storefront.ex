defmodule BlueJet.Storefront do
  use BlueJet, :context

  alias BlueJet.Storefront.{Policy, Service}

  #
  # MARK: Order
  #
  def list_order(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "list_order") do
      do_list_order(authorized_args)
    else
      other -> other
    end
  end

  def do_list_order(args) do
    total_count =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.count_order(args[:opts])

    all_count =
      %{ filter: args[:all_count_filter] }
      |> Service.count_order(args[:opts])

    orders =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.list_order(args[:opts])
      |> Translation.translate(args[:locale], args[:default_locale])

    response = %AccessResponse{
      meta: %{
        locale: args[:locale],
        all_count: all_count,
        total_count: total_count,
      },
      data: orders
    }

    {:ok, response}
  end

  def create_order(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "create_order") do
      do_create_order(authorized_args)
    else
      other -> other
    end
  end

  def do_create_order(args) do
    with {:ok, order} <- Service.create_order(args[:fields], args[:opts]) do
      order = Translation.translate(order, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: order }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def get_order(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "get_order") do
      do_get_order(authorized_args)
    else
      other -> other
    end
  end

  def do_get_order(args) do
    order =
      Service.get_order(args[:identifiers], args[:opts])
      |> Translation.translate(args[:locale], args[:default_locale])

    if order do
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: order }}
    else
      {:error, :not_found}
    end
  end

  def update_order(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "update_order") do
      do_update_order(authorized_args)
    else
      other -> other
    end
  end

  def do_update_order(args) do
    with {:ok, order} <- Service.update_order(args[:identifiers], args[:fields], args[:opts]) do
      order = Translation.translate(order, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: order }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete_order(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "delete_order") do
      do_delete_order(authorized_args)
    else
      other -> other
    end
  end

  def do_delete_order(args) do
    with {:ok, _} <- Service.delete_order(args[:identifiers], args[:opts]) do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  #
  # MARK: Order Line Item
  #
  def create_order_line_item(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "create_order_line_item") do
      do_create_order_line_item(authorized_args)
    else
      other -> other
    end
  end

  def do_create_order_line_item(args) do
    with {:ok, oli} <- Service.create_order_line_item(args[:fields], args[:opts]) do
      oli = Translation.translate(oli, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: oli }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def update_order_line_item(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "update_order_line_item") do
      do_update_order_line_item(authorized_args)
    else
      other -> other
    end
  end

  def do_update_order_line_item(args) do
    with {:ok, oli} <- Service.update_order_line_item(args[:identifiers], args[:fields], args[:opts]) do
      oli = Translation.translate(oli, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: oli }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete_order_line_item(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "delete_order_line_item") do
      do_delete_order_line_item(authorized_args)
    else
      other -> other
    end
  end

  def do_delete_order_line_item(args) do
    with {:ok, _} <- Service.delete_order_line_item(args[:identifiers], args[:opts]) do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end
end
