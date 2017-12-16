defmodule BlueJet.Plugs.Include do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn = %Plug.Conn{ query_params: %{ "include" => include } }, _) do
    query_params = Map.put(conn.query_params, "include", Inflex.underscore(include))
    conn = %{ conn | query_params: query_params }

    assign(conn, :preloads, to_preloads(include))
  end
  def call(conn, opts), do: assign(conn, :preloads, opts[:default])

  @doc """
  Deserialize the include string to a keyword list that can be used for preload.
  """
  def to_preloads(preloads_string) do
    preloads = String.split(preloads_string, ",")
    preloads = Enum.sort_by(preloads, fn(item) -> length(String.split(item, ".")) end)

    Enum.reduce(preloads, [], fn(item, acc) ->
      preload = to_preload(item)

      # If its a chained preload and the root key already exist in acc
      # then we need to merge it.
      with [{key, value}] <- preload,
           true <- Keyword.has_key?(acc, key)
      do
        # Merge chained preload with existing root key
        existing_value = Keyword.get(acc, key)
        index = Enum.find_index(acc, fn(item) ->
          is_tuple(item) && elem(item, 0) == key
        end)

        List.update_at(acc, index, fn(_) ->
          {key, List.flatten([existing_value]) ++ value}
        end)
      else
        _ ->
          acc ++ preload
      end
    end)
  end
  def to_preload(preload) do
    preload =
      preload
      |> Inflex.underscore()
      |> String.split(".")
      |> Enum.map(fn(item) -> String.to_atom(item) end)

    nestify(preload)
  end

  defp nestify(list) when length(list) == 1 do
    [Enum.at(list, 0)]
  end
  defp nestify(list) do
    r_nestify(list)
  end
  defp r_nestify(list) do
    case length(list) do
      1 -> Enum.at(list, 0)
      _ ->
        [head | tail] = list
        Keyword.put([], head, r_nestify(tail))
    end
  end
end
