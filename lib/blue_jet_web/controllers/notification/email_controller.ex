defmodule BlueJetWeb.EmailController do
  use BlueJetWeb, :controller

  alias BlueJet.Notification

  action_fallback BlueJetWeb.FallbackController

  def index(conn, _),
    do: default(conn, :index, &Notification.list_email/1)

  def show(conn, %{"id" => _}),
    do: default(conn, :show, &Notification.get_email/1)
end
