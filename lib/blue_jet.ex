defmodule BlueJet do
  @moduledoc """
  BlueJet keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def context do
    quote do
      alias BlueJet.Repo
      alias BlueJet.Translation
      alias BlueJet.AccessRequest
      alias BlueJet.AccessResponse

      import Ecto
      import Ecto.Query

      import BlueJet.ContextHelpers
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

      def put_external_resources(struct_or_structs, targets, options) when is_list(targets) and length(targets) == 0 do
        struct_or_structs
      end

      def put_external_resources(structs, targets, options) when is_list(structs) do
        Enum.map(structs, fn(struct) ->
          put_external_resources(struct, targets, options)
        end)
      end

      def put_external_resources(struct, targets, options) when is_list(targets) do
        [target | rest] = targets

        struct
        |> put_external_resources(target, options)
        |> put_external_resources(rest, options)
      end

      def put_external_resources(struct, target, options) when is_atom(target) do
        put_external_resources(struct, {target, nil}, options)
      end
    end
  end

  def service do
    quote do
      alias BlueJet.Repo

      defp get_pagination(fields) do
        Map.merge(%{ size: 20, number: 1 }, fields[:pagination] || %{})
      end

      defp get_preloads(opts, account) do
        preloads = opts[:preloads] || %{}
        path = preloads[:path] || []

        opts =
          preloads[:opts] || %{}
          |> Map.put(:account, account)

        %{ path: path, opts: opts }
      end

      defp get_filter(fields) do
        fields[:filter] || %{}
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
    end
  end

  def proxy do
    quote do
      alias BlueJet.AccessRequest

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
