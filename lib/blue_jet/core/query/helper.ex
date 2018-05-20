defmodule BlueJet.Query.Helper do
  import Ecto.Query

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

  def get_preload_filter(opts, key) do
    filters = opts[:filters] || %{}
    filters[key] || %{}
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
end