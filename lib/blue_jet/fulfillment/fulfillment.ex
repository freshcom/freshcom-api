defmodule BlueJet.Fulfillment do
  use BlueJet, :context
  use BlueJet.EventEmitter, namespace: :fulfillment

  alias BlueJet.Fulfillment.CrmService
  alias BlueJet.Fulfillment.Service
  alias BlueJet.Fulfillment.FulfillmentItem

  #
  # MARK: Fulfillment Package
  #
  def list_fulfillment_package(request) do
    with {:ok, request} <- preprocess_request(request, "fulfillment.list_fulfillment_package") do
      request
      |> do_list_fulfillment_package()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_fulfillment_package(request = %{ account: account, filter: filter }) do
    total_count =
      %{ filter: filter, search: request.search }
      |> Service.count_fulfillment_package(%{ account: account })

    all_count =
      %{ filter: request.count_filter[:all] }
      |> Service.count_fulfillment_package(%{ account: account })

    fulfillment_packages =
      %{ filter: filter, search: request.search }
      |> Service.list_fulfillment_package(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    response = %AccessResponse{
      meta: %{
        locale: request.locale,
        all_count: all_count,
        total_count: total_count,
      },
      data: fulfillment_packages
    }

    {:ok, response}
  end

  def delete_fulfillment_package(request) do
    with {:ok, request} <- preprocess_request(request, "goods.delete_fulfillment_package") do
      request
      |> do_delete_fulfillment_package()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_delete_fulfillment_package(%{ account: account, params: %{ "id" => id } }) do
    with {:ok, _} <- Service.delete_fulfillment_package(id, %{ account: account }) do
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
    with {:ok, request} <- preprocess_request(request, "fulfillment.list_fulfillment_item") do
      request
      |> do_list_fulfillment_item()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_fulfillment_item(request = %{ account: account, filter: filter }) do
    total_count =
      %{ filter: filter, search: request.search }
      |> Service.count_fulfillment_item(%{ account: account })

    all_count =
      %{ filter: request.count_filter[:all] }
      |> Service.count_fulfillment_item(%{ account: account })

    fulfillment_items =
      %{ filter: filter, search: request.search }
      |> Service.list_fulfillment_item(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    response = %AccessResponse{
      meta: %{
        locale: request.locale,
        all_count: all_count,
        total_count: total_count
      },
      data: fulfillment_items
    }

    {:ok, response}
  end

  defp fulfillment_item_response(nil, _), do: {:error, :not_found}

  defp fulfillment_item_response(fulfillment_item, request = %{ account: account }) do
    preloads = FulfillmentItem.Query.preloads(request.preloads, role: request.role)

    fulfillment_item =
      fulfillment_item
      |> Repo.preload(preloads)
      |> FulfillmentItem.put_external_resources(request.preloads, %{ account: account, role: request.role, locale: request.locale })
      |> Translation.translate(request.locale, account.default_locale)

    {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: fulfillment_item }}
  end

  def create_fulfillment_item(request) do
    with {:ok, request} <- preprocess_request(request, "storefront.create_fulfillment_item") do
      request
      |> do_create_fulfillment_item()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_fulfillment_item(request = %{ account: account }) do
    with {:ok, fulfillment_item} <- Service.create_fulfillment_item(request.fields, %{ account: account }) do
      fulfillment_item_response(fulfillment_item, request)
    else
      {:error, changeset} ->
        {:error, %AccessResponse{ errors: changeset.errors }}
    end
  end

  def update_fulfillment_item(request) do
    with {:ok, request} <- preprocess_request(request, "fulfillment.update_fulfillment_item") do
      request
      |> do_update_fulfillment_item()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_update_fulfillment_item(request = %{ account: account, params: %{ "id" => id }}) do
    with {:ok, fulfillment_item} <- Service.update_fulfillment_item(id, request.fields, get_sopts(request)) do
      fulfillment_item = Translation.translate(fulfillment_item, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: fulfillment_item }}
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