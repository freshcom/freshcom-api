defmodule BlueJetWeb.Controller.Helpers do

  def extract_errors(%{ valid?: false, errors: errors }) do
    extract_errors(errors)
  end
  def extract_errors(changeset = %{ valid?: true }), do: changeset
  def extract_errors(errors) do
    Enum.reduce(errors, [], fn({ field, { msg, opts } }, acc) ->
      msg = Enum.reduce(opts, msg, fn({ key, value }, acc) ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)

      title = if opts[:validation] do
        "#{humanize(field)} #{msg}"
      else
        msg
      end

      mc = cond do
        String.contains?(msg, "taken") -> "taken"

        true -> nil
      end

      {vc, meta} = Keyword.pop(opts, :validation)
      {ec, meta} = Keyword.pop(meta, :code)

      code = ec || vc || mc || "invalid"
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

  def underscore_value(map, keys) do
    Enum.reduce(map, map, fn({k, v}, acc) ->
      if Enum.member?(keys, k) && acc[k] do
        %{ acc | k => Inflex.underscore(v) }
      else
        acc
      end
    end)
  end
end