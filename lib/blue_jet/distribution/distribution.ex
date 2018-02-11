defmodule BlueJet.Distribution do
  use BlueJet, :context
  use BlueJet.EventEmitter, namespace: :distribution

  alias Ecto.Multi

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

  def do_list_fulfillment(request = %{ account: account, filter: filter, pagination: pagination }) do
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
    fulfillment =
      Fulfillment.Query.default()
      |> Fulfillment.Query.for_account(account.id)
      |> Repo.get(id)
      |> Repo.preload(:line_items)

    if fulfillment do
      statements =
        Multi.new()
        |> Multi.delete(:fulfillment, fulfillment)
        |> Multi.run(:after_delete, fn(%{ fulfillment: fulfillment }) ->
            emit_event("distribution.fulfillment.after_delete", %{ fulfillment: fulfillment })
           end)

      {:ok, _, _, _} = Repo.transaction(statements)
      {:ok, %AccessResponse{}}
    else
      {:error, :not_found}
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

  def do_list_fulfillment_line_item(request = %{ account: account, filter: filter, pagination: pagination }) do
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
        all_count: total_count,
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
    fulfillment_line_item =
      FulfillmentLineItem.Query.default()
      |> FulfillmentLineItem.Query.for_account(account.id)
      |> Repo.get(id)

    with %FulfillmentLineItem{} <- fulfillment_line_item,
         changeset = %{ valid?: true } <- FulfillmentLineItem.changeset(fulfillment_line_item, request.fields, request.locale, account.default_locale)
    do
      statements =
        Multi.new()
        |> Multi.update(:fulfillment_line_item, changeset)
        |> Multi.run(:after_update, fn(%{ fulfillment_line_item: fli }) ->
            emit_event("distribution.fulfillment_line_item.after_update", %{ fulfillment_line_item: fli, changeset: changeset })
           end)

      {:ok, %{ fulfillment_line_item: fli }} = Repo.transaction(statements)
      fulfillment_line_item_response(fli, request)
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      nil ->
        {:error, :not_found}

      changeset ->
        {:error, %AccessResponse{ errors: changeset.errors }}
    end
  end
end