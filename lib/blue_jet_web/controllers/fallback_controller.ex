defmodule BlueJetWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use BlueJetWeb, :controller

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(404)
    |> render(BlueJetWeb.ErrorView, :"404")
  end

  def call(conn, {:error, :access_denied}) do
    conn
    |> put_status(403)
    |> render(BlueJetWeb.ErrorView, :"403")
  end
end
