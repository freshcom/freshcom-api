defmodule BlueJet.Plugs.Locale do
  import Plug.Conn

  def init(default), do: default

  def call(%Plug.Conn{ params: %{ "locale" => locale } } = conn, _default) do
    assign(conn, :locale, locale)
  end
  def call(conn, default), do: assign(conn, :locale, default)
end
