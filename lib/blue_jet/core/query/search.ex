defmodule BlueJet.Query.Search do
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
end