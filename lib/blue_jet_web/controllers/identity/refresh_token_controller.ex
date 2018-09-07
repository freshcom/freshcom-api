defmodule BlueJetWeb.RefreshTokenController do
  use BlueJetWeb, :controller

  alias BlueJet.Identity

  plug :scrub_params, "data" when action in [:create, :update]

  def show(conn, _),
    do: default(conn, :show, &Identity.get_refresh_token/1)
end
