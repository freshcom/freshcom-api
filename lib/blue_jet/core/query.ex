defmodule BlueJet.Query do
  import Ecto.Query

  def for_account(query, nil) do
    from q in query, where: is_nil(q.account_id)
  end

  def for_account(query, account_id) do
    from q in query, where: q.account_id == ^account_id
  end

  def sort_by(query, sort) do
    from q in query, order_by: ^sort
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

  def search(query, columns, keyword), do: search_default_locale(query, columns, keyword)
  def search(query, _, nil, _, _, _), do: query
  def search(query, _, "", _, _, _), do: query

  def search(query, columns, keyword, locale, default_locale, _) when is_nil(locale) or (locale == default_locale) do
    search_default_locale(query, columns, keyword)
  end

  def search(query, columns, keyword, locale, _, translatable_columns) do
    search_translations(query, columns, keyword, locale, translatable_columns)
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

  def lock_exclusively(query) do
    lock(query, "FOR UPDATE")
  end
end