defmodule BlueJet.Crm do
  use BlueJet, :context

  alias BlueJet.Crm.{Policy, Service}

  #
  # MARK: Customer
  #
  def list_customer(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "list_customer") do
      do_list_customer(authorize_args)
    else
      other -> other
    end
  end

  def do_list_customer(args) do
    total_count =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.count_customer(args[:opts])

    all_count = Service.count_customer(args[:opts])

    customers =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.list_customer(args[:opts])
      |> Translation.translate(args[:locale], args[:default_locale])

    response = %AccessResponse{
      meta: %{
        locale: args[:locale],
        all_count: all_count,
        total_count: total_count,
      },
      data: customers
    }

    {:ok, response}
  end

  def create_customer(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "create_customer") do
      do_create_customer(authorize_args)
    else
      other -> other
    end
  end

  def do_create_customer(args) do
    case Service.create_customer(args[:fields], args[:opts]) do
      {:ok, customer} ->
        customer = Translation.translate(customer, args[:locale], args[:default_locale])
        {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: customer }}

      {:error, changeset} ->
        {:error, %AccessResponse{ errors: changeset.errors }}
    end
  end

  def get_customer(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "get_customer") do
      do_get_customer(authorize_args)
    else
      other -> other
    end
  end

  def do_get_customer(args) do
    customer =
      Service.get_customer(args[:identifiers], args[:opts])
      |> Translation.translate(args[:locale], args[:default_locale])

    if customer do
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: customer }}
    else
      {:error, :not_found}
    end
  end

  def update_customer(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "update_customer") do
      do_update_customer(authorize_args)
    else
      other -> other
    end
  end

  def do_update_customer(args) do
    with {:ok, customer} <- Service.update_customer(args[:id], args[:fields], args[:opts]) do
      customer = Translation.translate(customer, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: customer }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete_customer(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "delete_customer") do
      do_delete_customer(authorize_args)
    else
      other -> other
    end
  end

  def do_delete_customer(args) do
    with {:ok, _} <- Service.delete_customer(args[:id], args[:opts]) do
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
    filter =
      filter
      |> Map.put(:status, "committed")
      |> Map.put(:point_account_id, point_account_id)

    total_count =
      %{ filter: filter }
      |> Service.count_point_transaction(%{ account: account })

    all_count =
      %{ filter: %{ point_account_id: point_account_id, status: "committed" } }
      |> Service.count_point_transaction(%{ account: account })

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

  defp point_transaction_fields_by_role(request = %{ role: "customer", fields: fields }) do
    fields = Map.put(fields, "status", "pending")
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

  def do_get_point_transaction(request = %{ account: account, params: params }) do
    point_transaction =
      atom_map(params)
      |> Service.get_point_transaction(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    if point_transaction do
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: point_transaction }}
    else
      {:error, :not_found}
    end
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
      pt = Translation.translate(pt, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: pt }}
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
    with {:ok, _} <- Service.delete_point_transaction(id, %{ account: account }) do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end
end
