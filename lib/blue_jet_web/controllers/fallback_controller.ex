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

  def call(conn, {:error, :access_denied, reason}) do
    conn
    |> put_status(403)
    |> render(BlueJetWeb.ErrorView, :"403", %{reason: reason})
  end

  def call(conn, {:error, :unprocessable_for_test_account}) do
    reason = "You are making request against a test account, but this endpoint only work for live account. Please try again using a live access token."

    conn
    |> put_status(422)
    |> render(BlueJetWeb.ErrorView, :"422", %{code: "unprocessable_for_test_mode", reason: reason})
  end

  def call(conn, {:error, :unprocessable_for_live_user}) do
    reason = "You are making request using a test access token which is incapable of updating live user. Please try again using a live access token or try updating a test user instead."

    conn
    |> put_status(422)
    |> render(BlueJetWeb.ErrorView, :"422", %{code: "unprocessable_for_live_user", reason: reason})
  end
end
