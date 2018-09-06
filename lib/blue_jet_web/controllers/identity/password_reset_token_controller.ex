defmodule BlueJetWeb.PasswordResetTokenController do
  use BlueJetWeb, :controller

  alias BlueJet.Identity

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def create(conn, %{"data" => %{"type" => "PasswordResetToken"}}),
    do: default(conn, :create, &Identity.create_password_reset_token/1, status: :no_content)
end
