defmodule BlueJetWeb.EmailVerificationController do
  use BlueJetWeb, :controller

  alias BlueJet.Identity

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def create(conn, %{"data" => %{"type" => "EmailVerification"}}),
    do: default(conn, :create, &Identity.create_email_verification/1, status: :no_content)
end
