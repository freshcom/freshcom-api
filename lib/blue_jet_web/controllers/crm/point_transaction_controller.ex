defmodule BlueJetWeb.PointTransactionController do
  use BlueJetWeb, :controller

  alias BlueJet.CRM

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def index(%{assigns: assigns} = conn, params) do
    filter =
      (assigns[:filter] || %{})
      |> Map.put("point_account_id", params["point_account_id"])

    conn
    |> assign(:filter, filter)
    |> default(:index, &CRM.list_point_transaction/1)
  end

  def create(conn, %{"data" => %{"type" => "PointTransaction"}}),
    do: default(conn, :create, &CRM.create_point_transaction/1, fields: ["point_account_id"])

  def show(conn, %{"id" => _}),
    do: default(conn, :show, &CRM.get_point_transaction/1)

  def update(conn, %{"id" => _, "data" => %{"type" => "PointTransaction"}}),
    do: default(conn, :update, &CRM.update_point_transaction/1)

  def delete(conn, %{"id" => _}),
    do: default(conn, :delete, &CRM.delete_point_transaction/1)
end
