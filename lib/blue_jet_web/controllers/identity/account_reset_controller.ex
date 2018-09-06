defmodule BlueJetWeb.AccountResetController do
  use BlueJetWeb, :controller

  alias BlueJet.Identity

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create]

  def create(conn, %{"data" => %{"type" => "AccountReset"}}),
    do: default(conn, :create, &Identity.reset_account/1, status: :no_content)
end
