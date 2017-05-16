defmodule BlueJet.TokenController do
  use BlueJet.Web, :controller

  def create(conn, params) do
    with {:ok, token} <- BlueJet.Authentication.get_token(params) do
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
