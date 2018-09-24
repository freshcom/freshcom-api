defmodule BlueJetWeb.DepositableController do
  @moduledoc false

  use BlueJetWeb, :controller

  alias BlueJet.Goods

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn, _),
    do: default(conn, :index, &Goods.list_depositable/1)

  def create(conn, %{"data" => %{"type" => "Depositable"}}),
    do: default(conn, :create, &Goods.create_depositable/1)

  def show(conn, %{"id" => _}),
    do: default(conn, :show, &Goods.get_depositable/1)

  def update(conn, %{"id" => _, "data" => %{"type" => "Depositable"}}),
    do: default(conn, :update, &Goods.update_depositable/1)

  def delete(conn, %{"id" => _}),
    do: default(conn, :delete, &Goods.delete_depositable/1)
end
