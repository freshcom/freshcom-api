defmodule BlueJet.Service.Default do
  alias BlueJet.Repo

  import BlueJet.Query
  import BlueJet.Service.{Option, Preload, Helper}

  def default(:list, type, query, opts) do
    account = extract_account(opts)
    pagination = extract_pagination(opts)
    filter = extract_filter(query)
    preload = extract_preload(opts)
    query_module = Module.concat([type, Query])

    query_module.default()
    |> query_module.search(query[:search], opts[:locale], account.default_locale)
    |> query_module.filter_by(filter)
    |> for_account(account.id)
    |> sort_by(opts[:sort] || [desc: :updated_at])
    |> paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> preload(preload[:paths], preload[:opts])
  end

  def default(:count, type, query, opts) do
    account = extract_account(opts)
    filter = extract_filter(query)
    query_module = Module.concat([type, Query])

    query_module.default()
    |> query_module.search(query[:search], opts[:locale], account.default_locale)
    |> query_module.filter_by(filter)
    |> for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def default(:create, type, fields, opts) do
    account = extract_account(opts)
    preload = extract_preload(opts)

    changeset =
      type
      |> struct(%{account_id: account.id, account: account})
      |> type.changeset(:insert, fields)

    case Repo.insert(changeset) do
      {:ok, data} ->
        {:ok, preload(data, preload[:paths], preload[:opts])}

      other ->
        other
    end
  end

  def default(:get, type, identifiers, opts) do
    account = extract_account(opts)
    preload = extract_preload(opts)
    filter = extract_nil_filter(identifiers)
    clauses = extract_clauses(identifiers)
    query_module = Module.concat([type, Query])

    query_module.default()
    |> for_account(account.id)
    |> query_module.filter_by(filter)
    |> Repo.get_by(clauses)
    |> put_account(account)
    |> preload(preload[:paths], preload[:opts])
  end

  def default(:delete, identifiers, opts, get_fun) do
    get_fun.(identifiers, opts)
    |> delete(opts)
  end

  def default(:update, data, fields, opts), do: update(data, fields, opts)

  def default(:update, identifiers, fields, opts, get_fun) do
    get_fun.(identifiers, opts)
    |> update(fields, opts)
  end

  def default(:delete, data, opts), do: delete(data, opts)

  def default(:delete_all, type, %{account: %{mode: "test"}} = opts) do
    account = extract_account(opts)
    batch_size = opts[:batch_size] || 1000
    query_module = Module.concat([type, Query])

    data_ids =
      query_module.default()
      |> for_account(account.id)
      |> paginate(size: batch_size, number: 1)
      |> id_only()
      |> Repo.all()

    query_module.default()
    |> query_module.filter_by(%{id: data_ids})
    |> Repo.delete_all()

    if length(data_ids) === batch_size do
      delete_all(type, opts)
    else
      :ok
    end
  end

  def list(type, fields, opts) do
    account = extract_account(opts)
    pagination = extract_pagination(opts)
    preloads = extract_preloads(opts, account)
    filter = extract_filter(fields)
    query_module = Module.concat([type, Query])

    query_module.default()
    |> query_module.search(fields[:search], opts[:locale], account.default_locale)
    |> query_module.filter_by(filter)
    |> for_account(account.id)
    |> paginate(size: pagination[:size], number: pagination[:number])
    |> sort_by(fields[:sort] || [desc: :updated_at])
    |> Repo.all()
    |> preload(preloads[:path], preloads[:opts])
  end

  def count(type, fields, opts) do
    account = extract_account(opts)
    filter = extract_filter(fields)
    query_module = Module.concat([type, Query])

    query_module.default()
    |> query_module.search(fields[:search], opts[:locale], account.default_locale)
    |> query_module.filter_by(filter)
    |> for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def create(type, fields, opts) do
    account = extract_account(opts)
    preloads = extract_preloads(opts, account)

    changeset =
      struct(type, %{ account_id: account.id, account: account })
      |> type.changeset(:insert, fields)

    with {:ok, resource} <- Repo.insert(changeset) do
      resource = preload(resource, preloads[:path], preloads[:opts])
      {:ok, resource}
    else
      other -> other
    end
  end

  def get(type, identifiers, opts) do
    account = extract_account(opts)
    preloads = extract_preloads(opts, account)
    filter = extract_nil_filter(identifiers)
    clauses = extract_clauses(identifiers)
    query_module = Module.concat([type, Query])

    query_module.default()
    |> for_account(account.id)
    |> query_module.filter_by(filter)
    |> Repo.get_by(clauses)
    |> preload(preloads[:path], preloads[:opts])
  end

  def update(nil, _, _), do: {:error, :not_found}

  def update(data, fields, opts) do
    account = extract_account(opts)
    preload = extract_preload(opts)

    changeset =
      %{data | account: account}
      |> data.__struct__.changeset(:update, fields, opts[:locale])

    case Repo.update(changeset) do
      {:ok, data} ->
        {:ok, preload(data, preload[:paths], preload[:opts])}

      other ->
        other
    end
  end

  def delete(nil, _), do: {:error, :not_found}

  def delete(data, opts) do
    account = extract_account(opts)

    %{data | account: account}
    |> data.__struct__.changeset(:delete)
    |> Repo.delete()
  end

  def delete_all(type, opts = %{account: %{mode: "test"} = account}) do
    batch_size = opts[:batch_size] || 1000
    query_module = Module.concat([type, Query])

    data_ids =
      query_module.default()
      |> for_account(account.id)
      |> paginate(size: batch_size, number: 1)
      |> query_module.id_only()
      |> Repo.all()

    query_module.default()
    |> query_module.filter_by(%{id: data_ids})
    |> Repo.delete_all()

    if length(data_ids) === batch_size do
      delete_all(type, opts)
    else
      :ok
    end
  end

  def put_account(nil, _), do: nil

  def put_account(data, account) do
    %{data | account: account}
  end
end