defmodule BlueJet.Controller.Helpers do
  import Ecto.Query

  def paginate(query, size: size, number: number) do
    limit = size
    offset = size * (number - 1)

    query
    |> limit(^limit)
    |> offset(^offset)
  end

  def search(model, column_name, keyword, locale) when keyword == nil or keyword == "" do
    model
  end

  def search(model, column_name, keyword, locale) when locale == "en" do
    keyword = "%#{keyword}%"
    from m in model, where: ilike(field(m, ^column_name), ^keyword)
  end

  def search(model, column_name, keyword, locale) do
    keyword = "%#{keyword}%"
    column_name = Atom.to_string(column_name)
    from m in model, where: ilike(fragment("?->?->>?", m.translations, ^locale, ^column_name), ^keyword)
  end
end