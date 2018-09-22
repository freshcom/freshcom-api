defmodule BlueJetWeb.CustomerController do
  use BlueJetWeb, :controller

  alias BlueJet.Crm

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn, _),
    do: default(conn, :index, &Crm.list_customer/1)

  def create(conn, %{"data" => %{"type" => "Customer"}}),
    do: default(conn, :create, &Crm.create_customer/1)

  @valid_identifiers [:id, :code, :phone_number, :email, :name]
  def show(conn, _),
    do: default(conn, :show, &Crm.get_customer/1, identifiers: @valid_identifiers)

  def update(conn, %{"id" => _, "data" => %{"type" => "Customer"}}),
    do: default(conn, :update, &Crm.update_customer/1)

  def delete(conn, %{"id" => _}),
    do: default(conn, :delete, &Crm.delete_customer/1)
end
