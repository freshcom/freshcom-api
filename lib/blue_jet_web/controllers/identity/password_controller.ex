defmodule BlueJetWeb.PasswordController do
  use BlueJetWeb, :controller

  alias BlueJet.Identity

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def update(conn, %{"data" => %{"type" => "Password"}}),
    do: default(conn, :update, &Identity.update_password/1, status: :no_content, identifiers: [:id, :reset_token])
end
