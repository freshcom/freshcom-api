defmodule BlueJetWeb.PasswordController do
  use BlueJetWeb, :controller

  alias JaSerializer.Params
  alias BlueJet.Identity

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def update(conn = %{ assigns: assigns }, params = %{ "data" => data = %{ "type" => "Password" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{"id" => params["id"]},
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads]
    }

    case Identity.update_password(request) do
      {:ok, _} ->
        send_resp(conn, :no_content, "")

      {:error, %{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))

      other -> other
    end
  end
end
