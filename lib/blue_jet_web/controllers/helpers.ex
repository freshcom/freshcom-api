defmodule BlueJetWeb.Controller.Helpers do
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

  def extract_errors(%Ecto.Changeset{ valid?: false, errors: errors }) do
    extract_errors(errors)
  end
  def extract_errors(changeset = %Ecto.Changeset{ valid?: true }), do: changeset
  def extract_errors(errors) do
    Enum.reduce(errors, [], fn({ field, { msg, opts } }, acc) ->
      msg = Enum.reduce(opts, msg, fn({ key, value }, acc) ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)

      {full_error_message, opts} = Keyword.pop(opts, :full_error_message)
      title = if full_error_message do
        msg
      else
        "#{humanize(field)} #{msg}"
      end

      {vc, meta} = Keyword.pop(opts, :validation)
      {ec, meta} = Keyword.pop(meta, :code)

      code = ec || vc || "invalid"
      error = %{ source: %{ pointer: pointer_for(field) }, code: Inflex.camelize(code, :lower), title: title }

      error =
        case Enum.empty?(meta) do
          true -> error
          _ -> Map.put(error, :meta, Enum.into(meta, %{}))
        end

      acc ++ [error]
    end)
  end


  def humanize(atom) when is_atom(atom), do: humanize(Atom.to_string(atom))
  def humanize(bin) when is_binary(bin) do
    bin =
      if String.ends_with?(bin, "_id") do
        binary_part(bin, 0, byte_size(bin) - 3)
      else
        bin
      end

    bin |> String.replace("_", " ") |> String.capitalize
  end

  def pointer_for(:fields), do: "/data"
  def pointer_for(:attributes), do: "/data/attributes"
  def pointer_for(:relationships), do: "/data/relationships"
  def pointer_for(field) do
    case Regex.run(~r/(.*)_id$/, to_string(field)) do
      nil      -> "/data/attributes/#{Inflex.camelize(field, :lower)}"
      [_, rel] -> "/data/relationships/#{Inflex.camelize(rel, :lower)}"
    end
  end

  def camelize_map(map) do
    Enum.reduce(map, %{}, fn({key, value}, acc) ->
      Map.put(acc, Inflex.camelize(key, :lower), value)
    end)
  end

  # def translate_collection(collection, "en"), do: collection
  # def translate_collection(collection, locale) do
  #   Enum.map(collection, fn(item) -> translate(item, locale) end)
  # end

  # def translate(collection, "en"), do: collection
  # def translate(struct, locale) do
  #   t_attributes = Map.new(Map.get(struct.translations, locale, %{}), fn({k, v}) -> { String.to_atom(k), v } end)
  #   Map.merge(struct, t_attributes)
  # end

end