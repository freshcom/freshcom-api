defmodule BlueJet.Plugs.Filter do
  import Plug.Conn

  def init(opts), do: opts

  def call(%Plug.Conn{query_params: %{"filter" => filter}} = conn, _default) do
    filter = Enum.reduce(filter, %{}, fn({k, v}, acc) ->
      Map.put(acc, Inflex.underscore(k), v)
    end)

    assign(conn, :filter, filter)
  end

  def call(conn, opts), do: assign(conn, :filter, opts[:default])
end
