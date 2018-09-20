defmodule BlueJetWeb.ProductCollectionController do
  use BlueJetWeb, :controller

  alias BlueJet.Catalogue

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn, _),
    do: default(conn, :index, &Catalogue.list_product_collection/1)

  def create(conn, %{"data" => %{"type" => "ProductCollection"}}),
    do: default(conn, :create, &Catalogue.create_product_collection/1)

  def show(conn, %{"id" => _}),
    do: default(conn, :show, &Catalogue.get_product_collection/1)

  def update(conn, %{"id" => _, "data" => %{"type" => "ProductCollection"}}),
    do: default(conn, :update, &Catalogue.update_product_collection/1)

  def delete(conn, %{"id" => _}),
    do: default(conn, :delete, &Catalogue.delete_product_collection/1)
end
