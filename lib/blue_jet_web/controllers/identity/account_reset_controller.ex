defmodule BlueJetWeb.AccountResetController do
  use BlueJetWeb, :controller

  alias BlueJet.Identity

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create]

  def create(conn = %{ assigns: assigns }, %{"data" => %{ "type" => "AccountReset" }}) do
    request = %AccessRequest{
      vas: assigns[:vas],
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Identity.reset_account(request) do
      {:ok, _} ->
        send_resp(conn, :accepted, "")

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(changeset))

      other -> other
    end
  end
end
