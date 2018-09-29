defmodule BlueJetWeb.BalanceSettingsController do
  use BlueJetWeb, :controller

  alias BlueJet.Balance

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def show(conn, _),
    do: default(conn, :show, &Balance.get_settings/1)

  def update(conn, %{"data" => %{"type" => "Settings"}}),
    do: default(conn, :update, &Balance.update_settings/1)
end
