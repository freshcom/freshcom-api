defmodule BlueJet.Context.Helpers do
  import Ecto.Query

  def paginate(query, size: size, number: number) do
    limit = size
    offset = size * (number - 1)

    query
    |> limit(^limit)
    |> offset(^offset)
  end

  def search(model, _, nil, _), do: model
  def search(model, _, "", _), do: model
  def search(model, columns, keyword, "en") do
    keyword = "%#{keyword}%"

    Enum.reduce(columns, model, fn(column, query) ->
      from q in query, or_where: ilike(fragment("?::varchar", field(q, ^column)), ^keyword)
    end)
  end
  def search(model, columns, keyword, locale) do
    keyword = "%#{keyword}%"

    Enum.reduce(columns, model, fn(column, query) ->
      if Enum.member?(model.translatable_fields(), column) do
        column = Atom.to_string(column)
        from q in query, or_where: ilike(fragment("?->?->>?", q.translations, ^locale, ^column), ^keyword)
      else
        from q in query, or_where: ilike(fragment("?::varchar", field(q, ^column)), ^keyword)
      end
    end)
  end

  def filter_by(query, filter) do
    filter = Enum.filter(filter, fn({_, value}) -> value end)
    from q in query, where: ^filter
  end
end