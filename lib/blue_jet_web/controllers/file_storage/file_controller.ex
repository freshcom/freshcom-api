defmodule BlueJetWeb.FileController do
  use BlueJetWeb, :controller

  alias BlueJet.FileStorage

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn, _),
    do: default(conn, :index, &FileStorage.list_file/1)

  def create(conn, %{"data" => %{"type" => "File"}}),
    do: default(conn, :create, &FileStorage.create_file/1)

  def show(conn, %{"id" => _}),
    do: default(conn, :show, &FileStorage.get_file/1)

  def update(conn, %{"id" => _, "data" => %{"type" => "File"}}),
    do: default(conn, :update, &FileStorage.update_file/1)

  def delete(conn, %{"id" => _}),
    do: default(conn, :delete, &FileStorage.delete_file/1)
end
