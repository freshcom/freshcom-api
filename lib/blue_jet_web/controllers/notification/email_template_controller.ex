defmodule BlueJetWeb.EmailTemplateController do
  use BlueJetWeb, :controller

  alias BlueJet.Notification

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn, _),
    do: default(conn, :index, &Notification.list_email_template/1)

  def create(conn, %{"data" => %{"type" => "EmailTemplate"}}),
    do: default(conn, :create, &Notification.create_email_template/1)

  def show(conn, %{"id" => _}),
    do: default(conn, :show, &Notification.get_email_template/1)

  def update(conn, %{"id" => _, "data" => %{"type" => "EmailTemplate"}}),
    do: default(conn, :update, &Notification.update_email_template/1)

  def delete(conn, %{"id" => _}),
    do: default(conn, :delete, &Notification.delete_email_template/1)
end
