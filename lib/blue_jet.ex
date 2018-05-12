defmodule BlueJet do
  @moduledoc """
  BlueJet keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def context do
    quote do
      alias BlueJet.Translation
      alias BlueJet.AccessRequest
      alias BlueJet.AccessResponse

      defp list(type, request) do
        count_function = String.to_atom("count_" <> type)
        list_function = String.to_atom("list_" <> type)
        policy_module = Module.concat([__MODULE__, Policy])
        service_module = Module.concat([__MODULE__, Service])

        with {:ok, args} <- policy_module.authorize(request, "list_" <> type) do
          fields = %{ filter: args[:filter], search: args[:search] }

          total_count = apply(service_module, count_function, [fields, args[:opts]])
          all_count = apply(service_module, count_function, [%{ filter: args[:all_count_filter] }, args[:opts]])

          resources =
            apply(service_module, list_function, [fields, args[:opts]])
            |> Translation.translate(args[:locale], args[:default_locale])

          response = %AccessResponse{
            meta: %{
              locale: args[:locale],
              all_count: all_count,
              total_count: total_count
            },
            data: resources
          }

          {:ok, response}
        else
          other -> other
        end
      end

      defp create(type, request) do
        create_function = String.to_atom("create_" <> type)
        policy_module = Module.concat([__MODULE__, Policy])
        service_module = Module.concat([__MODULE__, Service])

        with {:ok, args} <- policy_module.authorize(request, "create_" <> type),
             {:ok, resource} <- apply(service_module, create_function, [args[:fields], args[:opts]])
        do
          response = %AccessResponse{
            meta: %{ locale: args[:locale] },
            data: resource
          }

          {:ok, response}
        else
          other -> other
        end
      end

      defp get(type, request) do
        get_function = String.to_atom("get_" <> type)
        policy_module = Module.concat([__MODULE__, Policy])
        service_module = Module.concat([__MODULE__, Service])

        with {:ok, args} <- policy_module.authorize(request, "get_" <> type),
             resource = %{} <- apply(service_module, get_function, [args[:identifiers], args[:opts]])
        do
          resource = Translation.translate(resource, args[:locale], args[:default_locale])

          response = %AccessResponse{
            meta: %{ locale: args[:locale] },
            data: resource
          }

          {:ok, response}
        else
          nil -> {:error, :not_found}

          other -> other
        end
      end

      defp update(type, request) do
        update_function = String.to_atom("update_" <> type)
        policy_module = Module.concat([__MODULE__, Policy])
        service_module = Module.concat([__MODULE__, Service])

        with {:ok, args} <- policy_module.authorize(request, "update_" <> type),
             {:ok, resource} <- apply(service_module, update_function, [args[:identifiers], args[:fields], args[:opts]])
        do
          resource = Translation.translate(resource, args[:locale], args[:default_locale])

          response = %AccessResponse{
            meta: %{ locale: args[:locale] },
            data: resource
          }

          {:ok, response}
        else
          {:error, %{ errors: errors }} ->
            {:error, %AccessResponse{ errors: errors }}

          other -> other
        end
      end

      defp delete(type, request) do
        delete_function = String.to_atom("delete_" <> type)
        policy_module = Module.concat([__MODULE__, Policy])
        service_module = Module.concat([__MODULE__, Service])

        with {:ok, args} <- policy_module.authorize(request, "delete_" <> type),
             {:ok, _} <- apply(service_module, delete_function, [args[:identifiers], args[:opts]])
        do
          {:ok, %AccessResponse{}}
        else
          {:error, %{ errors: errors }} ->
            {:error, %AccessResponse{ errors: errors }}

          other -> other
        end
      end
    end
  end

  def service do
    quote do
      alias BlueJet.Repo

      defp extract_account(opts) do
        identity_service =
          Atom.to_string(__MODULE__)
          |> String.split(".")
          |> Enum.drop(-1)
          |> Enum.join(".")
          |> Module.concat(IdentityService)

        opts[:account] || identity_service.get_account(opts)
      end

      defp extract_account_id(opts) do
        opts[:account_id] || extract_account(opts).id
      end

      defp extract_pagination(fields) do
        Map.merge(%{ size: 20, number: 1 }, fields[:pagination] || %{})
      end

      defp extract_preloads(opts, account) do
        preloads = opts[:preloads] || %{}
        path = preloads[:path] || []

        opts = preloads[:opts] || %{}
        opts = Map.put(opts, :account, account)

        %{ path: path, opts: opts }
      end

      defp extract_filter(fields) do
        fields[:filter] || %{}
      end

      defp extract_nil_filter(map) do
        Enum.reduce(map, %{}, fn({k, v}, acc) ->
          if is_nil(v) do
            Map.put(acc, k, v)
          else
            acc
          end
        end)
      end

      defp extract_clauses(map) do
        Enum.reduce(map, %{}, fn({k, v}, acc) ->
          if is_nil(v) do
            acc
          else
            Map.put(acc, k, v)
          end
        end)
      end

      defp preload([], _, _), do: []
      defp preload(nil, _, _), do: nil
      defp preload(struct_or_structs, path, opts) do
        struct_module = if is_list(struct_or_structs) do
          Enum.at(struct_or_structs, 0).__struct__
        else
          struct_or_structs.__struct__
        end
        query_module = Module.concat(struct_module, Query)
        proxy_module = Module.concat(struct_module, Proxy)
        preload_query = query_module.preloads(path, opts)

        struct_or_structs
        |> Repo.preload(preload_query)
        |> proxy_module.put(path, opts)
      end

      defp list(type, fields, opts) do
        account = extract_account(opts)
        pagination = extract_pagination(opts)
        preloads = extract_preloads(opts, account)
        filter = extract_filter(fields)
        query_module = Module.concat([type, Query])

        query_module.default()
        |> query_module.search(fields[:search], opts[:locale], account.default_locale)
        |> query_module.filter_by(filter)
        |> query_module.for_account(account.id)
        |> query_module.paginate(size: pagination[:size], number: pagination[:number])
        |> query_module.order_by(fields[:sort] || [desc: :updated_at])
        |> Repo.all()
        |> preload(preloads[:path], preloads[:opts])
      end

      defp count(type, fields, opts) do
        account = extract_account(opts)
        filter = extract_filter(fields)
        query_module = Module.concat([type, Query])

        query_module.default()
        |> query_module.search(fields[:search], opts[:locale], account.default_locale)
        |> query_module.filter_by(filter)
        |> query_module.for_account(account.id)
        |> Repo.aggregate(:count, :id)
      end

      defp create(type, fields, opts) do
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

      defp get(type, identifiers, opts) do
        account = extract_account(opts)
        preloads = extract_preloads(opts, account)
        filter = extract_nil_filter(identifiers)
        clauses = extract_clauses(identifiers)
        query_module = Module.concat([type, Query])

        query_module.default()
        |> query_module.for_account(account.id)
        |> query_module.filter_by(filter)
        |> Repo.get_by(clauses)
        |> preload(preloads[:path], preloads[:opts])
      end

      defp update(data, fields, opts) do
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

      defp delete(data, opts) do
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

      defp delete_all(type, opts = %{ account: account = %{ mode: "test" }}) do
        batch_size = opts[:batch_size] || 1000
        query_module = Module.concat([type, Query])

        data_ids =
          query_module.default()
          |> query_module.for_account(account.id)
          |> query_module.paginate(size: batch_size, number: 1)
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
  end

  def data do
    quote do
      use Ecto.Schema
      import Ecto.Changeset

      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
      #######

      import Ecto
      import Ecto.Query
      import BlueJet.Validation

      alias BlueJet.Repo
      alias BlueJet.Translation
    end
  end

  def proxy do
    quote do
      alias BlueJet.AccessRequest

      defp get_sopts(%{ account_id: account_id, account: nil }) do
        %{ account_id: account_id }
      end

      defp get_sopts(%{ account: account }) do
        %{ account: account }
      end

      def put(nil, _, _), do: nil

      def put(struct_or_structs, targets, options) when is_list(targets) and length(targets) == 0 do
        struct_or_structs
      end

      def put(structs, targets, options) when is_list(structs) do
        Enum.map(structs, fn(struct) ->
          put(struct, targets, options)
        end)
      end

      def put(struct, targets, options) when is_list(targets) do
        [target | rest] = targets

        struct
        |> put(target, options)
        |> put(rest, options)
      end

      def put(struct, target, options) when is_atom(target) do
        put(struct, {target, nil}, options)
      end
    end
  end

  def query do
    quote do
      import Ecto.Query

      def order_by(query, order) do
        from q in query, order_by: ^order
      end

      def search_default_locale(query, columns, keyword) do
        keyword = "%#{keyword}%"

        Enum.reduce(columns, query, fn(column, query) ->
          from q in query, or_where: ilike(fragment("?::varchar", field(q, ^column)), ^keyword)
        end)
      end

      def search_translations(query, columns, keyword, locale, translatable_columns) do
        keyword = "%#{keyword}%"

        Enum.reduce(columns, query, fn(column, query) ->
          if Enum.member?(translatable_columns, column) do
            column = Atom.to_string(column)
            from q in query, or_where: ilike(fragment("?->?->>?", q.translations, ^locale, ^column), ^keyword)
          else
            from q in query, or_where: ilike(fragment("?::varchar", field(q, ^column)), ^keyword)
          end
        end)
      end

      def search(query, columns, keyword), do: search_default_locale(query, columns, keyword)
      def search(query, _, nil, _, _, _), do: query
      def search(query, _, "", _, _, _), do: query

      def search(query, columns, keyword, locale, default_locale, _) when locale == default_locale do
        search_default_locale(query, columns, keyword)
      end

      def search(query, columns, keyword, locale, _, translatable_columns) do
        search_translations(query, columns, keyword, locale, translatable_columns)
      end

      def filter_by(query, filter, filterable_fields) do
        filter = Map.take(filter, filterable_fields)

        Enum.reduce(filter, query, fn({k, v}, acc_query) ->
          cond do
            is_list(v) ->
              from q in acc_query, where: field(q, ^k) in ^v

            is_nil(v) ->
              from q in acc_query, where: is_nil(field(q, ^k))

            true ->
              from q in acc_query, where: field(q, ^k) == ^v
          end
        end)
      end

      def paginate(query, size: size, number: number) do
        limit = size
        offset = size * (number - 1)

        query
        |> limit(^limit)
        |> offset(^offset)
      end

      def id_only(query) do
        from r in query, select: r.id
      end

      defp get_preload_filter(opts, key) do
        filters = opts[:filters] || %{}
        filters[key] || %{}
      end

      def preloads(targets) when is_list(targets) and length(targets) == 0 do
        []
      end

      def preloads(targets) when is_list(targets) do
        [target | rest] = targets
        preloads(target) ++ preloads(rest)
      end

      def preloads(targets, options) when is_list(targets) and length(targets) == 0 do
        []
      end

      def preloads(targets, options) when is_list(targets) do
        [target | rest] = targets
        preloads(target, options) ++ preloads(rest, options)
      end

      def preloads(target, options) when is_atom(target) do
        preloads({target, nil}, options)
      end

      def preloads({nil, nil}, _) do
        []
      end
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
