defmodule BlueJetWeb.UserController do
  use BlueJetWeb, :controller

  alias BlueJet.Identity
  alias JaSerializer.Params

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def create(conn = %{ assigns: assigns }, %{ "data" => data = %{ "type" => "User" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads]
    }

    case Identity.create_user(request) do
      {:ok, %{data: %{account_id: nil}}} ->
        send_resp(conn, :no_content, "")

      {:ok, %{data: user, meta: meta}} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: user, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      {:error, %AccessResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))

      other -> other
    end
  end

  def show(conn = %{ assigns: assigns }, params) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: params,
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Identity.get_user(request) do
      {:ok, %{ data: user, meta: meta }} ->
        render(conn, "show.json-api", data: user, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      other -> other
    end
  end

  def update(conn = %{ assigns: assigns }, params = %{ "data" => data = %{ "type" => "User" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ "id" => params["id"] },
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Identity.update_user(request) do
      {:ok, %{ data: user, meta: meta }} ->
        render(conn, "show.json-api", data: user, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      {:error, %{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))

      other -> other
    end
  end

  def delete(conn = %{ assigns: assigns }, %{"id" => id}) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ "id" => id }
    }

    case Identity.delete_user(request) do
      {:ok, _} -> send_resp(conn, :no_content, "")

      other -> other
    end
  end
end
