defmodule BlueJetWeb.PhoneVerificationCodeController do
  use BlueJetWeb, :controller

  alias BlueJet.Identity

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def create(conn, %{"data" => %{"type" => "PhoneVerificationCode"}}),
    do: default(conn, :create, &Identity.create_phone_verification_code/1, status: :no_content)
end
