defmodule BlueJetWeb.EmailConfirmationTokenController do
  use BlueJetWeb, :controller

  alias JaSerializer.Params
  alias BlueJet.Identity

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def create(conn = %{ assigns: assigns }, %{ "data" => data = %{ "type" => "EmailConfirmationToken" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads]
    }

    case Identity.create_email_confirmation_token(request) do
      {:ok, _} ->
        send_resp(conn, :accepted, "")

      {:error, %{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))

      other -> other
    end
  end
end
