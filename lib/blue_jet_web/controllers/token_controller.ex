defmodule BlueJetWeb.TokenController do
  use BlueJetWeb, :controller

  alias BlueJet.Identity

  def create(conn, params) do
    with {:ok, token} <- Identity.authenticate(params) do
      conn
      |> put_status(:ok)
      |> json(token)
    else
      {:error, errors} ->
        conn
        |> put_status(:bad_request)
        |> json(errors)
    end
  end
end
