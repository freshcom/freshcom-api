defmodule BlueJetWeb.CardController do
  use BlueJetWeb, :controller

  alias BlueJet.Balance

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn, _),
    do: default(conn, :index, &Balance.list_card/1)

  def create(conn, %{"data" => %{"type" => "Card"}}),
    do: default(conn, :create, &Balance.create_card/1, normalize: ["status"])

  def show(conn, %{"id" => _}),
    do: default(conn, :show, &Balance.get_card/1)

  def update(conn, %{"id" => _, "data" => %{"type" => "Card"}}),
    do: default(conn, :update, &Balance.update_card/1)

  def delete(conn, %{"id" => _}),
    do: default(conn, :delete, &Balance.delete_card/1)
end
