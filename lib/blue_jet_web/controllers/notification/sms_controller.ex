defmodule BlueJetWeb.SMSController do
  use BlueJetWeb, :controller

  alias BlueJet.Notification

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn, _),
    do: default(conn, :index, &Notification.list_sms/1)

  def show(conn, %{"id" => _}),
    do: default(conn, :show, &Notification.get_sms/1)
end
