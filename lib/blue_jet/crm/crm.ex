defmodule BlueJet.Crm do
  use BlueJet, :context

  alias BlueJet.Crm.{Customer, PointTransaction}
  alias BlueJet.Crm.Service

  #
  # MARK: Customer
  #
  def list_customer(request) do
    with {:ok, request} <- preprocess_request(request, "crm.list_customer") do
      request
      |> do_list_customer()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_customer(request = %{ account: account, filter: filter }) do
    total_count =
      %{ filter: filter, search: request.search }
      |> Service.count_customer(%{ account: account })

    all_count = Service.count_customer(%{ account: account })

    customers =
      %{ filter: filter, search: request.search }
      |> Service.list_customer(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    response = %AccessResponse{
      meta: %{
        locale: request.locale,
        all_count: all_count,
        total_count: total_count,
      },
      data: customers
    }

    {:ok, response}
  end

  defp customer_response(nil, _), do: {:error, :not_found}

  defp customer_response(customer, request = %{ account: account }) do
    preloads = Customer.Query.preloads(request.preloads, role: request.role)

    customer =
      customer
      |> Repo.preload(preloads)
      |> Customer.put_external_resources(request.preloads, %{ account: account, role: request.role, locale: request.locale })
      |> Translation.translate(request.locale, account.default_locale)

    {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: customer }}
  end

  def create_customer(request) do
    with {:ok, request} <- preprocess_request(request, "crm.create_customer") do
      request
      |> do_create_customer()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_customer(request = %{ account: account }) do
    fields = Map.merge(request.fields, %{
      "role" => "customer"
    })

    case Service.create_customer(fields, %{ account: account }) do
      {:ok, customer} ->
        customer_response(customer, request)

      {:error, changeset} ->
        {:error, %AccessResponse{ errors: changeset.errors }}
    end
  end

  def get_customer(request) do
    with {:ok, request} <- preprocess_request(request, "crm.get_customer") do
      request
      |> do_get_customer()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_get_customer(request = %{ account: account, params: params }) do
    customer =
      atom_map(params)
      |> Service.get_customer(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    if customer do
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: customer }}
    else
      {:error, :not_found}
    end
  end

  def update_customer(request) do
    with {:ok, request} <- preprocess_request(request, "crm.update_customer") do
      request
      |> do_update_customer()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_update_customer(request = %{ account: account, params: %{ "id" => id } }) do
    with {:ok, customer} <- Service.update_customer(id, request.fields, get_sopts(request)) do
      customer = Translation.translate(customer, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: customer }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete_customer(request) do
    with {:ok, request} <- preprocess_request(request, "crm.delete_customer") do
      request
      |> do_delete_customer()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_delete_customer(%{ account: account, params: %{ "id" => id } }) do
    with {:ok, _} <- Service.delete_customer(id, %{ account: account }) do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  #
  # PointTransaction
  #
  def list_point_transaction(request) do
    with {:ok, request} <- preprocess_request(request, "crm.list_point_transaction") do
      request
      |> AccessRequest.transform_by_role()
      |> do_list_point_transaction()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  # TODO: check role, customer can only view its own point transaction
  def do_list_point_transaction(request = %{
    account: account,
    filter: filter,
    params: %{ "point_account_id" => point_account_id }
  }) do
    total_count =
      %{ filter: filter }
      |> Service.count_point_transaction(%{ account: account })

    all_count =
      %{ filter: %{ point_account_id: point_account_id } }
      |> Service.count_point_transaction(%{ account: account })

    filter = Map.put(filter, :point_account_id, point_account_id)
    point_transactions =
      %{ filter: filter }
      |> Service.list_point_transaction(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    response = %AccessResponse{
      meta: %{
        locale: request.locale,
        all_count: all_count,
        total_count: total_count,
      },
      data: point_transactions
    }

    {:ok, response}
  end

  defp point_transaction_response(nil, _), do: {:error, :not_found}

  defp point_transaction_response(point_transaction, request = %{ account: account }) do
    preloads = PointTransaction.Query.preloads(request.preloads, role: request.role)

    point_transaction =
      point_transaction
      |> Repo.preload(preloads)
      |> PointTransaction.put_external_resources(request.preloads, %{ account: account, role: request.role, locale: request.locale })
      |> Translation.translate(request.locale, account.default_locale)

    {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: point_transaction }}
  end

  defp point_transaction_fields_by_role(request = %{ role: "customer", fields: fields }) do
    fields = Map.put(fields, :status, "pending")
    Map.put(request, :fields, fields)
  end

  defp point_transaction_fields_by_role(request), do: request

  def create_point_transaction(request) do
    with {:ok, request} <- preprocess_request(request, "crm.create_point_transaction") do
      request
      |> point_transaction_fields_by_role()
      |> do_create_point_transaction()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_point_transaction(request = %{ account: account, params: %{ "point_account_id" => point_account_id } }) do
    fields = Map.merge(request.fields, %{ "point_account_id" => point_account_id })

    with {:ok, point_transaction} <- Service.create_point_transaction(fields, get_sopts(request)) do
      point_transaction = Translation.translate(point_transaction, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: point_transaction }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def get_point_transaction(request) do
    with {:ok, request} <- preprocess_request(request, "crm.get_point_transaction") do
      request
      |> do_get_point_transaction()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_get_point_transaction(request = %{ account: account, params: %{ "id" => id } }) do
    point_transaction =
      PointTransaction.Query.default()
      |> PointTransaction.Query.for_account(account.id)
      |> Repo.get(id)

    point_transaction_response(point_transaction, request)
  end

  def update_point_transaction(request) do
    with {:ok, request} <- preprocess_request(request, "crm.update_point_transaction") do
      request
      |> do_update_point_transaction
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_update_point_transaction(request = %{ account: account, params: %{ "id" => id } }) do
    with {:ok, pt} <- Service.update_point_transaction(id, request.fields, %{ account: account }) do
      point_transaction_response(pt, request)
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete_point_transaction(request) do
    with {:ok, request} <- preprocess_request(request, "crm.delete_point_transaction") do
      request
      |> do_delete_point_transaction()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_delete_point_transaction(%{ account: account, params: %{ "id" => id } }) do
    point_transaction =
      PointTransaction.Query.default()
      |> PointTransaction.Query.for_account(account.id)
      |> Repo.get(id)

    if point_transaction.amount == 0 do
      Repo.delete!(point_transaction)
      {:ok, %AccessResponse{}}
    else
      {:error, :not_found}
    end
  end
end
