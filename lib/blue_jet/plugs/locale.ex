defmodule BlueJet.Plugs.Locale do
  import Plug.Conn

  def init(default), do: default

  def call(conn = %Plug.Conn{ query_params: %{ "locale" => locale } }, _default) do
    Gettext.put_locale(BlueJet.Gettext, "en")
    assign(conn, :locale, locale)
  end
  def call(conn, default), do: assign(conn, :locale, default)
end
