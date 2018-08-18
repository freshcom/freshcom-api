defmodule BlueJetWeb.AccountController do
  use BlueJetWeb, :controller

  alias BlueJet.Identity
  alias JaSerializer.Params

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn = %{ assigns: assigns }, _) do
    request = %AccessRequest{
      vas: assigns[:vas],
      pagination: %{ size: assigns[:page_size], number: assigns[:page_number] },
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Identity.list_account(request) do
      {:ok, %{ data: accounts, meta: meta }} ->
        render(conn, "index.json-api", data: accounts, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      other ->
        other
    end
  end

  def show(conn = %{ assigns: assigns }, _) do
    request = %AccessRequest{
      vas: assigns[:vas],
      locale: assigns[:locale]
    }

    case Identity.get_account(request) do
      {:ok, %{ data: account, meta: meta }} ->
        render(conn, "show.json-api", data: account, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      other -> other
    end
  end

  def update(conn = %{ assigns: assigns }, %{"data" => data = %{"type" => "Account", "attributes" => _account_params}}) do
    request = %AccessRequest{
      vas: assigns[:vas],
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Identity.update_account(request) do
      {:ok, %{ data: account, meta: meta }} ->
        render(conn, "show.json-api", data: account, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      {:error, %{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))

      other -> other
    end
  end
end
