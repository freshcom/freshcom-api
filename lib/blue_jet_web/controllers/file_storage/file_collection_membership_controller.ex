defmodule BlueJetWeb.FileCollectionMembershipController do
  use BlueJetWeb, :controller

  alias BlueJet.FileStorage

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def index(%{assigns: assigns} = conn, params) do
    filter = Map.merge(assigns[:filter], %{collection_id: params["file_collection_id"]})

    conn
    |> assign(:filter, filter)
    |> default(:index, &FileStorage.list_file_collection_membership/1)
  end

  def create(conn, %{"data" => %{"type" => "FileCollectionMembership"}}),
    do: default(conn, :create, &FileStorage.create_file_collection_membership/1)

  def show(conn, %{"id" => _}),
    do: default(conn, :show, &FileStorage.get_file_collection_membership/1)

  def update(conn, %{"id" => _, "data" => %{"type" => "FileCollectionMembership"}}),
    do: default(conn, :update, &FileStorage.update_file_collection_membership/1)

  def delete(conn, %{"id" => _}),
    do: default(conn, :delete, &FileStorage.delete_file_collection_membership/1)
end
