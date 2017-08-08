defmodule BlueJet.Plugs.Include do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn = %Plug.Conn{ query_params: %{ "include" => include } }, _) do
    query_params = Map.put(conn.query_params, "include", Inflex.underscore(include))
    conn = %{ conn | query_params: query_params }

    preloads = String.split(include, ",")
    preloads = Enum.sort_by(preloads, fn(item) -> length(String.split(item, ".")) end)

    preloads = Enum.reduce(preloads, [], fn(item, acc) ->
      acc ++ deserialize_preload(item)
    end)

    assign(conn, :preloads, preloads)
  end
  def call(conn, opts), do: assign(conn, :preloads, opts[:default])

  defp deserialize_preload(preload) do
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
