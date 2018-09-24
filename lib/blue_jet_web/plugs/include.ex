defmodule BlueJet.Plugs.Include do
  import Plug.Conn

  def init(opts), do: opts

  def call(%Plug.Conn{query_params: %{"include" => include}} = conn, _) do
    normalized_include = Inflex.underscore(include)
    query_params = Map.put(conn.query_params, "include", normalized_include)
    conn = %{conn | query_params: query_params}

    assign(conn, :include, normalized_include)
  end

  def call(conn, opts), do: assign(conn, :include, opts[:default])
end
