defmodule BlueJetWeb.AccountController do
  use BlueJetWeb, :controller

  alias BlueJet.Identity

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn, _),
    do: default(conn, :index, &Identity.list_account/1)

  def show(conn, _),
    do: default(conn, :show, &Identity.get_account/1)

  def update(conn, %{"data" => %{"type" => "Account"}}),
    do: default(conn, :update, &Identity.update_account/1)
end
