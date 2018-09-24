defmodule BlueJetWeb.AccountMembershipController do
  use BlueJetWeb, :controller

  alias BlueJet.Identity

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn, _) do
    conn
    |> assign(:include, "user,account")
    |> default(:index, &Identity.list_account_membership/1, normalize: ["role"], params: ["target"])
  end

  def update(conn, %{"id" => _, "data" => %{"type" => "AccountMembership"}}) do
    conn
    |> assign(:include, "user,account")
    |> default(:update, &Identity.update_account_membership/1, normalize: ["role"])
  end
end
