defmodule BlueJetWeb.ProductController do
  use BlueJetWeb, :controller

  alias BlueJet.Catalogue

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn, _),
    do: default(conn, :index, &Catalogue.list_product/1)

  def create(conn, %{"data" => %{"type" => "Product"}}),
    do: default(conn, :create, &Catalogue.create_product/1, normalize: ["kind", "name_sync"])

  def show(conn, %{"id" => _}),
    do: default(conn, :show, &Catalogue.get_product/1)

  def update(conn, %{"id" => _, "data" => %{"type" => "Product"}}),
    do: default(conn, :update, &Catalogue.update_product/1, normalize: ["kind", "name_sync"])

  def delete(conn, %{"id" => _}),
    do: default(conn, :delete, &Catalogue.delete_product/1)
end
