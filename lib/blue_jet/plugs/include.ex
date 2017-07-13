defmodule BlueJet.Plugs.Include do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn = %Plug.Conn{ query_params: %{ "include" => include } }, _default) do
    query_params = Map.put(conn.query_params, "include", Inflex.underscore(include))
    conn = %{ conn | query_params: query_params }

    include = String.split(include, ",")
    include = Enum.reduce(include, [], fn(item, acc) ->
      acc ++ [Inflex.underscore(item)]
    end)

    assign(conn, :include, include)
  end
  def call(conn, opts), do: assign(conn, :include, opts[:default])
end
