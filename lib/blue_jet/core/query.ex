defmodule BlueJet.Query do
  @moduledoc """
  This module defines some common query functions used when implementing service functions.

  This module also defines the functions that a query module should implement in
  order to be used with default service functions.
  """
  import Ecto.Query

  alias Ecto.Query

  @callback default() :: Query.t()

  @callback get_by(query :: Query.t(), identifiers :: map) :: Query.t()

  @callback filter_by(query :: Query.t(), filter :: map) :: Query.t()

  @callback search(
    query :: Query.t(),
    keyword :: String.t(),
    locale :: String.t(),
    default_locale :: String.t()
  ) :: Query.t()

  @callback preloads(path :: tuple, opts :: map) :: keyword

  @spec for_account(Query.t(), String.t() | nil) :: Query.t()
  def for_account(query, nil) do
    from q in query, where: is_nil(q.account_id)
  end

  def for_account(query, account_id) do
    from q in query, where: q.account_id == ^account_id
  end

  @spec sort_by(Query.t(), keyword(atom)) :: Query.t()
  def sort_by(query, sort) do
    from q in query, order_by: ^sort
  end

  @spec sort_by(Query.t(), keyword(integer)) :: Query.t()
  def paginate(query, size: size, number: number) do
    limit = size
    offset = size * (number - 1)

    query
    |> limit(^limit)
    |> offset(^offset)
  end

  @spec id_only(Query.t()) :: Query.t()
  def id_only(query) do
    from r in query, select: r.id
  end

  @spec except(Query.t(), keyword) :: Query.t()
  def except(query, conditions) do
    Enum.reduce(conditions, query, fn({k, v}, acc_query) ->
      from q in acc_query, where: field(q, ^k) != ^v
    end)
  end

  @spec lock_exclusively(Query.t()) :: Query.t()
  def lock_exclusively(query) do
    lock(query, "FOR UPDATE")
  end

  @spec filter_by(Query.t(), map, [atom]) :: Query.t()
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

  # TODO: change order of param to match spec
  @spec search(Query.t(), String.t(), [atom]) :: Query.t()
  def search(query, keyword, columns), do: search_default_locale(query, keyword, columns)

  @spec search(Query.t(), String.t(), String.t(), String.t(), [atom], [atom]) :: Query.t()
  def search(query, nil, _, _, _, _), do: query
  def search(query, "", _, _, _, _), do: query

  def search(query, keyword, locale, default_locale, columns, _) when is_nil(locale) or (locale == default_locale) do
    search_default_locale(query, keyword, columns)
  end

  def search(query, keyword, locale, _, columns, translatable_columns) do
    search_translations(query, keyword, locale, columns, translatable_columns)
  end

  defp search_default_locale(query, keyword, columns) do
    keyword = "%#{keyword}%"

    Enum.reduce(columns, query, fn(column, query) ->
      from q in query, or_where: ilike(fragment("?::varchar", field(q, ^column)), ^keyword)
    end)
  end

  defp search_translations(query, keyword, locale, columns, translatable_columns) do
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
end