defmodule BlueJet.Distribution do
  use BlueJet, :context
  use BlueJet.EventEmitter, namespace: :distribution

  alias Ecto.Multi

  alias BlueJet.Distribution.{Fulfillment, FulfillmentLineItem}

  defmodule Service do
    use BlueJet.EventEmitter, namespace: :distribution

    def create_fulfillment(fields, opts) do
      account_id = opts[:account_id] || opts[:account].id

      %Fulfillment{ account_id: account_id, account: opts[:account] }
      |> Fulfillment.changeset(fields)
      |> Repo.insert()
    end

    def create_fulfillment_line_item(fields, opts) do
      account_id = opts[:account_id] || opts[:account].id

      changeset =
        %FulfillmentLineItem{ account_id: account_id, account: opts[:account] }
        |> FulfillmentLineItem.changeset(fields)

      statements =
        Multi.new()
        |> Multi.insert(:fulfillment_line_item, changeset)
        |> Multi.run(:after_create, fn(%{ fulfillment_line_item: fli }) ->
            emit_event("distribution.fulfillment_line_item.after_create", %{ fulfillment_line_item: fli })
           end)

      case Repo.transaction(statements) do
        {:ok, %{ fulfillment_line_item: fli }} -> {:ok, fli}

        {:error, _, changeset, _} -> {:error, changeset}
      end
    end

    def list_fulfillment_line_item(%{ source_type: source_type, source_id: source_id }) do
      FulfillmentLineItem.Query.default()
      |> FulfillmentLineItem.Query.for_source(source_type, source_id)
      |> Repo.all()
    end
  end

  def list_fulfillment(request) do
    with {:ok, request} <- preprocess_request(request, "distribution.list_fulfillment") do
      request
      |> do_list_fulfillment()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_fulfillment(request = %{ account: account, filter: filter, pagination: pagination }) do
    data_query =
      Fulfillment.Query.default()
      |> filter_by(
          source_id: filter[:source_id],
          source_type: filter[:source_type],
          status: filter[:status],
          label: filter[:label]
         )
      |> Fulfillment.Query.for_account(account.id)

    total_count = Repo.aggregate(data_query, :count, :id)
    all_count =
      Fulfillment.Query.default()
      |> filter_by(source_id: filter[:source_id], source_type: filter[:source_type])
      |> Fulfillment.Query.for_account(account.id)
      |> Repo.aggregate(:count, :id)

    preloads = Fulfillment.Query.preloads(request.preloads, role: request.role)
    fulfillments =
      data_query
      |> paginate(size: pagination[:size], number: pagination[:number])
      |> Repo.all()
      |> Repo.preload(preloads)
      |> Fulfillment.put_external_resources(request.preloads, %{ account: account, role: request.role, locale: request.locale })
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

  defp fulfillment_response(nil, _), do: {:error, :not_found}

  defp fulfillment_response(fulfillment, request = %{ account: account }) do
    preloads = Fulfillment.Query.preloads(request.preloads, role: request.role)

    fulfillment =
      fulfillment
      |> Repo.preload(preloads)
      |> Fulfillment.put_external_resources(request.preloads, %{ account: account, role: request.role, locale: request.locale })
      |> Translation.translate(request.locale, account.default_locale)

    {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: fulfillment }}
  end

  def create_fulfillment(request) do
    with {:ok, request} <- preprocess_request(request, "distribution.create_fulfillment") do
      request
      |> do_create_fulfillment()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_fulfillment(request = %{ account: account }) do
    changeset =
      %Fulfillment{ account_id: account.id, account: account }
      |> Fulfillment.changeset(request.fields)

    with {:ok, fulfillment} <- Repo.insert(changeset) do
      fulfillment_response(fulfillment, request)
    else
      {:error, changeset} ->
        {:error, %AccessResponse{ errors: changeset.errors }}
    end
  end

  def get_fulfillment(request) do
    with {:ok, request} <- preprocess_request(request, "distribution.get_fulfillment") do
      request
      |> do_get_fulfillment()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_get_fulfillment(request = %{ account: account, params: %{ "id" => id } }) do
    fulfillment =
      Fulfillment.Query.default()
      |> Fulfillment.Query.for_account(account.id)
      |> Repo.get(id)

    fulfillment_response(fulfillment, request)
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
    data_query =
      FulfillmentLineItem.Query.default()
      |> filter_by(source_id: filter[:source_id], source_type: filter[:source_type])
      |> FulfillmentLineItem.Query.for_account(account.id)

    total_count = Repo.aggregate(data_query, :count, :id)

    preloads = FulfillmentLineItem.Query.preloads(request.preloads, role: request.role)
    flis =
      data_query
      |> paginate(size: pagination[:size], number: pagination[:number])
      |> Repo.all()
      |> Repo.preload(preloads)
      |> FulfillmentLineItem.put_external_resources(request.preloads, %{ account: account, role: request.role, locale: request.locale })
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