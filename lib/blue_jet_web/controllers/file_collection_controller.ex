defmodule BlueJetWeb.FileCollectionController do
  use BlueJetWeb, :controller

  alias JaSerializer.Params
  alias BlueJet.FileStorage

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn = %{ assigns: assigns }, params) do
    request = %AccessRequest{
      vas: assigns[:vas],
      search: params["search"],
      filter: assigns[:filter],
      pagination: %{ size: assigns[:page_size], number: assigns[:page_number] },
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    {:ok, %AccessResponse{ data: file_collections, meta: meta }} = FileStorage.list_file_collection(request)

    render(conn, "index.json-api", data: file_collections, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])
  end

  def create(conn = %{ assigns: assigns }, %{ "data" => data = %{ "type" => "FileCollection" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads]
    }

    case FileStorage.create_file_collection(request) do
      {:ok, %{ data: fc, meta: meta }} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: fc, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      {:error, %AccessResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))

      other -> other
    end
  end

  def show(conn = %{ assigns: assigns }, %{ "id" => fc_id }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ "id" => fc_id },
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case FileStorage.get_file_collection(request) do
      {:ok, %AccessResponse{ data: fc, meta: meta }} ->
        render(conn, "show.json-api", data: fc, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      other -> other
    end
  end

  def update(conn = %{ assigns: assigns }, %{ "id" => fc_id, "data" => data = %{ "type" => "FileCollection" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ "id" => fc_id },
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case FileStorage.update_file_collection(request) do
      {:ok, %AccessResponse{ data: fc }} ->
        render(conn, "show.json-api", data: fc, opts: [include: conn.query_params["include"]])

      {:error, %AccessResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))

      other -> other
    end
  end

  def delete(conn = %{ assigns: assigns }, %{ "id" => fc_id }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ "id" => fc_id }
    }

    {:ok, _} = FileStorage.delete_file_collection(request)

    send_resp(conn, :no_content, "")
  end
end
