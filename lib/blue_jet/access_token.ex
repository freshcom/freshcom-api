defmodule BlueJet.Plugs.AccessToken do
  require Logger
  import Plug.Conn

  def init(default), do: default

  def call(conn, _default) do
    with [auth] <- get_req_header(conn, "authorization"),
         ["Bearer", access_token] <- String.split(auth)
    do
      Logger.debug("Access Token: #{inspect peek_payload(access_token)}")
      assign(conn, :access_token, access_token)
    else
      _ -> conn
    end
  end

  defp peek_payload(nil), do: nil
  defp peek_payload(access_token) do
    try do
      %JOSE.JWT{fields: fields} = JOSE.JWT.peek_payload(access_token)
      fields
    rescue
      ArgumentError -> nil
    end
  end
end
