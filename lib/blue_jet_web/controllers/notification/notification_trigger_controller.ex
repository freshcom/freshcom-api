defmodule BlueJetWeb.NotificationTriggerController do
  use BlueJetWeb, :controller

  alias BlueJet.Notification

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn, _),
    do: default(conn, :index, &Notification.list_trigger/1)

  def create(conn, %{"data" => %{"type" => "EmailTemplate"}}),
    do: default(conn, :create, &Notification.create_trigger/1)

  def show(conn, %{"id" => _}),
    do: default(conn, :show, &Notification.get_trigger/1)

  def update(conn, %{"id" => _, "data" => %{"type" => "EmailTemplate"}}),
    do: default(conn, :update, &Notification.update_trigger/1)

  def delete(conn, %{"id" => _}),
    do: default(conn, :delete, &Notification.delete_trigger/1)
end
