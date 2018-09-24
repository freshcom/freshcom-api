defmodule BlueJet.Plugs.Fields do
  import Plug.Conn

  def init(default), do: default

  def call(%Plug.Conn{query_params: %{"fields" => fields}} = conn, _default) do
    fields = Enum.reduce(fields, %{}, fn({k, v}, acc) ->
      Map.put(acc, k, Inflex.underscore(v))
    end)

    assign(conn, :fields, fields)
  end
  def call(conn, default), do: assign(conn, :fields, default)
end
