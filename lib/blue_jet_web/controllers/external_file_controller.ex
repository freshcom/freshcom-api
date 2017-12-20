defmodule BlueJetWeb.ExternalFileController do
  use BlueJetWeb, :controller

  alias JaSerializer.Params
  alias BlueJet.FileStorage

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn = %{ assigns: assigns }, params) do
    request = %AccessRequest{
      vas: assigns[:vas],
      search: params["search"],
      params: %{ account_id: params["account_id"] },
      filter: assigns[:filter],
      pagination: %{ size: assigns[:page_size], number: assigns[:page_number] },
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    {:ok, %AccessResponse{ data: stockables, meta: meta }} = FileStorage.list_external_file(request)

    render(conn, "index.json-api", data: stockables, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])
  end

  def create(conn = %{ assigns: assigns }, %{ "data" => data = %{ "type" => "ExternalFile" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads]
    }

    case FileStorage.create_external_file(request) do
      {:ok, %{ data: external_file, meta: meta }} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: external_file, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      {:error, %{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))

      other -> other
    end
  end

  def show(conn = %{ assigns: assigns = %{ vas: %{ account_id: _ } } }, %{ "id" => ef_id }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ "id" => ef_id },
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case FileStorage.get_external_file(request) do
      {:ok, %{ data: external_file, meta: meta }} ->
        render(conn, "show.json-api", data: external_file, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      other -> other
    end
  end

  def update(conn = %{ assigns: assigns }, %{ "id" => ef_id, "data" => data = %{ "type" => "ExternalFile" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ "id" => ef_id },
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case FileStorage.update_external_file(request) do
      {:ok, %AccessResponse{ data: external_file, meta: meta }} ->
        render(conn, "show.json-api", data: external_file, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      {:error, %AccessResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))

      other -> other
    end
  end

  def delete(conn = %{ assigns: assigns }, %{ "id" => ef_id }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ "id" => ef_id }
    }

    FileStorage.delete_external_file(request)

    send_resp(conn, :no_content, "")
  end
end
