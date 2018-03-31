defmodule BlueJet.Storefront do
  use BlueJet, :context

  alias BlueJet.Storefront.CrmService
  alias BlueJet.Storefront.Service

  defp filter_by_role(request = %{ account: account, vas: vas, role: "customer" }) do
    customer = CrmService.get_customer(%{ user_id: vas[:user_id] }, %{ account: account })
    %{ request | filter: Map.put(request.filter, :customer_id, customer.id ) }
  end

  defp filter_by_role(request), do: request

  #
  # MARK: Order
  #
  def list_order(request) do
    with {:ok, request} <- preprocess_request(request, "storefront.list_order") do
      request
      |> filter_by_role()
      |> do_list_order()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_order(request = %{ account: account, filter: filter }) do
    filter = if !filter[:status] do
      Map.put(filter, :status, ["opened", "closed"])
    else
      filter
    end

    all_count_filter = Map.take(filter, [:status, :customer_id])
    total_count =
      %{ filter: filter, search: request.search }
      |> Service.count_order(%{ account: account })

    all_count =
      %{ filter: all_count_filter }
      |> Service.count_order(%{ account: account })

    orders =
      %{ filter: filter, search: request.search }
      |> Service.list_order(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    response = %AccessResponse{
      meta: %{
        locale: request.locale,
        all_count: all_count,
        total_count: total_count,
      },
      data: orders
    }

    {:ok, response}
  end

  def create_order(request) do
    with {:ok, request} <- preprocess_request(request, "storefront.create_order") do
      request
      |> do_create_order()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_order(request = %{ account: account }) do
    with {:ok, order} <- Service.create_order(request.fields, get_sopts(request)) do
      order = Translation.translate(order, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: order }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def get_order(request) do
    with {:ok, request} <- preprocess_request(request, "storefront.get_order") do
      request
      |> do_get_order()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_get_order(request = %{ account: account, params: %{ "id" => id } }) do
    order =
      %{ id: id }
      |> Service.get_order(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    if order do
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: order }}
    else
      {:error, :not_found}
    end
  end

  def update_order(request) do
    with {:ok, request} <- preprocess_request(request, "storefront.update_order") do
      request
      |> do_update_order()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_update_order(request = %{ role: role, account: account, params: %{ "id" => id }}) when role in ["guest", "customer"] do
    order = Service.get_order(%{ id: id }, %{ account: account })

    fields = cond do
      order.status == "cart" && order.grand_total_cents == 0 && request.fields["status"] == "opened" ->
        request.fields

      true ->
        Map.merge(request.fields, %{ "status" => order.status })
    end

    with {:ok, order} <- Service.update_order(id, fields, get_sopts(request)) do
      order = Translation.translate(order, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: order }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def do_update_order(request = %{ account: account, params: %{ "id" => id }}) do
    with {:ok, order} <- Service.update_order(id, request.fields, get_sopts(request)) do
      order = Translation.translate(order, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: order }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete_order(request) do
    with {:ok, request} <- preprocess_request(request, "storefront.delete_order") do
      request
      |> do_delete_order()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_delete_order(%{ account: account, params: %{ "id" => id } }) do
    with {:ok, _} <- Service.delete_order(id, %{ account: account }) do
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
    with {:ok, request} <- preprocess_request(request, "storefront.create_order_line_item") do
      request
      |> do_create_order_line_item()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_order_line_item(request = %{ account: account }) do
    with {:ok, oli} <- Service.create_order_line_item(request.fields, get_sopts(request)) do
      oli = Translation.translate(oli, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: oli }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def update_order_line_item(request) do
    with {:ok, request} <- preprocess_request(request, "storefront.update_order_line_item") do
      request
      |> do_update_order_line_item()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_update_order_line_item(request = %{ account: account, params: %{ "id" => id } }) do
    with {:ok, oli} <- Service.update_order_line_item(id, request.fields, %{ account: account }) do
      oli = Translation.translate(oli, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: oli }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete_order_line_item(request) do
    with {:ok, request} <- preprocess_request(request, "storefront.delete_order_line_item") do
      request
      |> do_delete_order_line_item()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_delete_order_line_item(%{ account: account, params: %{ "id" => id } }) do
    with {:ok, _} <- Service.delete_order_line_item(id, %{ account: account }) do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end
end
