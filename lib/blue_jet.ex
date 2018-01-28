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

  def proxy do
    quote do
      alias BlueJet.AccessRequest

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
