defmodule BlueJet.Service.Default do
  alias BlueJet.Repo

  import BlueJet.Utils, only: [atomize_keys: 2, take_nil_values: 1, drop_nil_values: 1]
  import BlueJet.Query
  import BlueJet.Service.Preload

  def normalize_identifiers(identifiers, query_module),
    do: atomize_keys(identifiers, query_module.identifiable_fields())

  def extract_account(opts, fallback_function \\ fn(_) -> nil end) do
    opts[:account] || fallback_function.(opts)
  end

  def extract_account_id(opts, fallback_function \\ fn(_) -> nil end) do
    opts[:account_id] || extract_account(opts, fallback_function).id
  end

  def extract_pagination(opts) do
    Map.merge(%{size: 20, number: 1}, opts[:pagination] || %{})
  end

  def extract_preloads(opts, account \\ nil) do
    account = account || extract_account(opts)
    preload = opts[:preloads] || opts[:preload] || %{} # TODO: remove opts[:preloads]
    path = preload[:path] || preload[:paths] || [] # TODO: remove preloads[:path]

    opts = preload[:opts] || %{}
    opts = Map.put(opts, :account, account)

    %{ path: path, opts: opts }
  end

  def extract_preload(opts) do
    account = extract_account(opts)
    include = opts[:include] || %{}

    paths = include[:paths] || ""
    opts = Map.put(include[:opts] || %{}, :account, account)

    %{paths: to_preload_paths(paths), opts: opts}
  end

  @doc """
  Converts JSON API style include string to a keyword list that can be passed
  in to `BlueJet.Repo.preload`.
  """
  @spec to_preload_paths(String.t()) :: keyword
  def to_preload_paths(include_paths) when byte_size(include_paths) == 0, do: []

  def to_preload_paths(include_paths) do
    preloads = String.split(include_paths, ",")
    preloads = Enum.sort_by(preloads, fn(item) -> length(String.split(item, ".")) end)

    Enum.reduce(preloads, [], fn(item, acc) ->
      preload = to_preload_path(item)

      # If its a chained preload and the root key already exist in acc
      # then we need to merge it.
      with [{key, value}] <- preload,
           true <- Keyword.has_key?(acc, key)
      do
        # Merge chained preload with existing root key
        existing_value = Keyword.get(acc, key)
        index = Enum.find_index(acc, fn(item) ->
          is_tuple(item) && elem(item, 0) == key
        end)

        List.update_at(acc, index, fn(_) ->
          {key, List.flatten([existing_value]) ++ value}
        end)
      else
        _ ->
          acc ++ preload
      end
    end)
  end

  defp to_preload_path(preload) do
    preload =
      preload
      |> Inflex.underscore()
      |> String.split(".")
      |> Enum.map(fn(item) -> String.to_existing_atom(item) end)

    nestify(preload)
  end

  defp nestify(list) when length(list) == 1 do
    [Enum.at(list, 0)]
  end

  defp nestify(list) do
    r_nestify(list)
  end

  defp r_nestify(list) do
    case length(list) do
      1 -> Enum.at(list, 0)
      _ ->
        [head | tail] = list
        Keyword.put([], head, r_nestify(tail))
    end
  end

  @spec default_list(module, map, map) :: [struct]
  def default_list(query_module, query, opts) do
    account = extract_account(opts)
    pagination = extract_pagination(opts)
    preload = extract_preload(opts)
    filter = atomize_keys(query[:filter], query_module.filterable_fields())

    query_module.default()
    |> query_module.search(query[:search], opts[:locale], account.default_locale)
    |> query_module.filter_by(filter)
    |> for_account(account.id)
    |> sort_by(opts[:sort] || [desc: :updated_at])
    |> paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> preload(preload[:paths], preload[:opts])
  end

  def default_count(query_module, query, opts) do
    account = extract_account(opts)
    filter = atomize_keys(query[:filter], query_module.filterable_fields())

    query_module.default()
    |> query_module.search(query[:search], opts[:locale], account.default_locale)
    |> query_module.filter_by(filter)
    |> for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def default_create(data_module, fields, opts) do
    account = extract_account(opts)
    preload = extract_preload(opts)

    changeset =
      data_module
      |> struct(%{account_id: account.id, account: account})
      |> data_module.changeset(:insert, fields)

    case Repo.insert(changeset) do
      {:ok, data} ->
        {:ok, preload(data, preload[:paths], preload[:opts])}

      other ->
        other
    end
  end

  def default_get(query_module, identifiers, opts) do
    account = extract_account(opts)
    preload = extract_preload(opts)
    identifiers = atomize_keys(identifiers, query_module.identifiable_fields())

    query_module.default()
    |> for_account(account.id)
    |> query_module.get_by(identifiers)
    |> Repo.one()
    |> put_account(account)
    |> preload(preload[:paths], preload[:opts])
  end

  def default_update(data, fields, opts), do: update(data, fields, opts)

  def default_update(identifiers, fields, opts, get_fun) do
    get_fun.(identifiers, opts)
    |> update(fields, opts)
  end

  def default_delete(identifiers, opts, get_fun) do
    get_fun.(identifiers, opts)
    |> delete(opts)
  end

  def default_delete(data, opts), do: delete(data, opts)

  def default_delete_all(query_module, %{account: %{mode: "test"}} = opts) do
    account = extract_account(opts)
    batch_size = opts[:batch_size] || 1000

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
      delete_all(query_module, opts)
    else
      :ok
    end
  end

  def list(type, fields, opts) do
    query_module = Module.concat([type, Query])
    account = extract_account(opts)
    pagination = extract_pagination(opts)
    preloads = extract_preloads(opts, account)
    filter = atomize_keys(fields, query_module.filterable_fields())

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
    query_module = Module.concat([type, Query])
    account = extract_account(opts)
    filter = atomize_keys(fields, query_module.filterable_fields())

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
    filter = take_nil_values(identifiers)
    clauses = drop_nil_values(identifiers)
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