defmodule BlueJetWeb.UserController do
  use BlueJetWeb, :controller

  alias BlueJet.Identity

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def create(conn, %{"data" => %{"type" => "User"}}) do
    request = build_context_request(conn, :create, normalize: ["role"])

    case Identity.create_user(request) do
      {:ok, %{data: %{account_id: nil}}} ->
        send_resp(conn, :no_content, "")

      {:ok, %{data: user, meta: meta}} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: user, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      {:error, %ContextResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))

      other ->
        other
    end
  end

  def show(conn, _),
    do: default(conn, :show, &Identity.get_user/1)

  def update(conn, %{"data" => %{"type" => "User"}}),
    do: default(conn, :update, &Identity.update_user/1, normalize: ["role"])

  def delete(conn, %{"id" => _}),
    do: default(conn, :delete, &Identity.delete_user/1)
end
