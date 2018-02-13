defmodule BlueJet.Distribution do
  use BlueJet, :context
  use BlueJet.EventEmitter, namespace: :distribution

  alias Ecto.Multi

  alias BlueJet.Distribution.CrmService
  alias BlueJet.Distribution.Service
  alias BlueJet.Distribution.{Fulfillment, FulfillmentLineItem}

  def list_fulfillment(request) do
    with {:ok, request} <- preprocess_request(request, "distribution.list_fulfillment") do
      request
      |> do_list_fulfillment()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_fulfillment(request = %{ account: account, filter: filter }) do
    total_count =
      %{ filter: filter, search: request.search }
      |> Service.count_fulfillment(%{ account: account })

    all_count =
      %{ filter: request.count_filter[:all] }
      |> Service.count_fulfillment(%{ account: account })

    fulfillments =
      %{ filter: filter, search: request.search }
      |> Service.list_fulfillment(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    response = %AccessResponse{
      meta: %{
        locale: request.locale,
        all_count: all_count,
        total_count: total_count,
      },
      data: fulfillments
    }

    {:ok, response}
  end

  def delete_fulfillment(request) do
    with {:ok, request} <- preprocess_request(request, "goods.delete_fulfillment") do
      request
      |> do_delete_fulfillment()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_delete_fulfillment(%{ account: account, params: %{ "id" => id } }) do
    with {:ok, _} <- Service.delete_fulfillment(id, %{ account: account }) do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  #
  # Fulfillment Line Item
  #
  def list_fulfillment_line_item(request) do
    with {:ok, request} <- preprocess_request(request, "distribution.list_fulfillment_line_item") do
      request
      |> do_list_fulfillment_line_item()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_fulfillment_line_item(request = %{ account: account, filter: filter }) do
    total_count =
      %{ filter: filter, search: request.search }
      |> Service.count_fulfillment_line_item(%{ account: account })

    all_count =
      %{ filter: request.count_filter[:all] }
      |> Service.count_fulfillment_line_item(%{ account: account })

    flis =
      %{ filter: filter, search: request.search }
      |> Service.list_fulfillment_line_item(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    response = %AccessResponse{
      meta: %{
        locale: request.locale,
        all_count: all_count,
        total_count: total_count
      },
      data: flis
    }

    {:ok, response}
  end

  defp fulfillment_line_item_response(nil, _), do: {:error, :not_found}

  defp fulfillment_line_item_response(fulfillment_line_item, request = %{ account: account }) do
    preloads = FulfillmentLineItem.Query.preloads(request.preloads, role: request.role)

    fulfillment_line_item =
      fulfillment_line_item
      |> Repo.preload(preloads)
      |> FulfillmentLineItem.put_external_resources(request.preloads, %{ account: account, role: request.role, locale: request.locale })
      |> Translation.translate(request.locale, account.default_locale)

    {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: fulfillment_line_item }}
  end

  def create_fulfillment_line_item(request) do
    with {:ok, request} <- preprocess_request(request, "storefront.create_fulfillment_line_item") do
      request
      |> do_create_fulfillment_line_item()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_fulfillment_line_item(request = %{ account: account }) do
    with {:ok, fli} <- Service.create_fulfillment_line_item(request.fields, %{ account: account }) do
      fulfillment_line_item_response(fli, request)
    else
      {:error, changeset} ->
        {:error, %AccessResponse{ errors: changeset.errors }}
    end
  end

  def update_fulfillment_line_item(request) do
    with {:ok, request} <- preprocess_request(request, "distribution.update_fulfillment_line_item") do
      request
      |> do_update_fulfillment_line_item()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_update_fulfillment_line_item(request = %{ account: account, params: %{ "id" => id }}) do
    with {:ok, fli} <- Service.update_fulfillment_line_item(id, request.fields, get_sopts(request)) do
      fli = Translation.translate(fli, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: fli }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  #
  # MARK: Unlock
  #
  defp filter_unlock_by_role(request = %{ account: account, vas: vas, role: "customer" }) do
    customer = CrmService.get_customer(%{ user_id: vas[:user_id] }, %{ account: account })
    %{ request | filter: Map.put(request.filter, :customer_id, customer.id ) }
  end

  defp filter_unlock_by_role(request), do: request

  def list_unlock(request) do
    with {:ok, request} <- preprocess_request(request, "storefront.list_unlock") do
      request
      |> filter_unlock_by_role()
      |> do_list_unlock()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_unlock(request = %{ account: account, filter: filter }) do
    total_count = Service.count_unlock(%{ filter: filter }, %{ account: account })
    all_count = Service.count_unlock(%{ filter: Map.take(filter, [:customer_id]) }, %{ account: account })
    unlocks =
      Service.list_unlock(%{ filter: filter }, get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    response = %AccessResponse{
      meta: %{
        locale: request.locale,
        all_count: all_count,
        total_count: total_count
      },
      data: unlocks
    }

    {:ok, response}
  end

  def create_unlock(request) do
    with {:ok, request} <- preprocess_request(request, "storefront.create_unlock") do
      request
      |> do_create_unlock()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_unlock(request = %{ account: account }) do
    with {:ok, unlock} <- Service.create_unlock(request.fields, get_sopts(request)) do
      unlock = Translation.translate(unlock, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: unlock }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def get_unlock(request) do
    with {:ok, request} <- preprocess_request(request, "storefront.get_unlock") do
      request
      |> do_get_unlock()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_get_unlock(request = %{ account: account, params: %{ "id" => id } }) do
    unlock =
      %{ id: id }
      |> Service.get_unlock(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    if unlock do
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: unlock }}
    else
      {:error, :not_found}
    end
  end

  def delete_unlock(request) do
    with {:ok, request} <- preprocess_request(request, "storefront.delete_unlock") do
      request
      |> do_delete_unlock()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_delete_unlock(%{ account: account, params: %{ "id" => id } }) do
    with {:ok, _} <- Service.delete_unlock(id, %{ account: account }) do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end
end