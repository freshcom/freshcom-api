defmodule BlueJetWeb.PriceController do
  use BlueJetWeb, :controller

  alias JaSerializer.Params
  alias BlueJet.Catalogue

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def index(%{assigns: assigns} = conn, params) do
    filter = Map.put(assigns[:filter], :product_id, params["product_id"])

    conn
    |> assign(:filter, filter)
    |> default(:index, &Catalogue.list_price/1)
  end

  def create(conn, %{"data" => %{"type" => "Price"}}),
    do: default(conn, :create, &Catalogue.create_price/1, params: ["product_id"])

  def show(conn, %{"id" => _}),
    do: default(conn, :show, &Catalogue.get_price/1)

  def update(conn, %{"id" => _, "data" => %{"type" => "Price"}}),
    do: default(conn, :update, &Catalogue.update_price/1)

  def delete(conn, %{"id" => _}),
    do: default(conn, :delete, &Catalogue.delete_price/1)
end
