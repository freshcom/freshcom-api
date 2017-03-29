defmodule BlueJet.Plugs.Locale do
  import Plug.Conn

  def init(default), do: default

  def call(%Plug.Conn{ params: %{ "locale" => locale } } = conn, _default) do
    Gettext.put_locale(BlueJet.Gettext, "en")
    assign(conn, :locale, locale)
  end
  def call(conn, default), do: assign(conn, :locale, default)
end
