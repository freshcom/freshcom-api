defmodule BlueJetWeb.SMSTemplateController do
  use BlueJetWeb, :controller

  alias BlueJet.Notification

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn, _),
    do: default(conn, :index, &Notification.list_sms_template/1)

  def create(conn, %{"data" => %{"type" => "SMSTemplate"}}),
    do: default(conn, :create, &Notification.create_sms_template/1)

  def show(conn, %{"id" => _}),
    do: default(conn, :show, &Notification.get_sms_template/1)

  def update(conn, %{"id" => _, "data" => %{"type" => "SMSTemplate"}}),
    do: default(conn, :update, &Notification.update_sms_template/1)

  def delete(conn, %{"id" => _}),
    do: default(conn, :delete, &Notification.delete_sms_template/1)
end
