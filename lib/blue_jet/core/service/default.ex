defmodule BlueJet.Service.Default do
  alias BlueJet.Repo
  import BlueJet.Query
  import BlueJet.Service.{Option, Preload, Helper}

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

  def update(data, fields, opts) do
    account = extract_account(opts)
    preloads = extract_preloads(opts, account)

    changeset =
      %{ data | account: account }
      |> data.__struct__.changeset(:update, fields, opts[:locale])

    with {:ok, data} <- Repo.update(changeset) do
      data = preload(data, preloads[:path], preloads[:opts])
      {:ok, data}
    else
      other -> other
    end
  end

  def delete(data, opts) do
    account = extract_account(opts)

    changeset =
      %{ data | account: account }
      |> data.__struct__.changeset(:delete)

    with {:ok, data} <- Repo.delete(changeset) do
      {:ok, data}
    else
      other -> other
    end
  end

  def delete_all(type, opts = %{ account: account = %{ mode: "test" }}) do
    batch_size = opts[:batch_size] || 1000
    query_module = Module.concat([type, Query])

    data_ids =
      query_module.default()
      |> for_account(account.id)
      |> paginate(size: batch_size, number: 1)
      |> query_module.id_only()
      |> Repo.all()

    query_module.default()
    |> query_module.filter_by(%{ id: data_ids })
    |> Repo.delete_all()

    if length(data_ids) === batch_size do
      delete_all(type, opts)
    else
      :ok
    end
  end
end