defmodule BlueJetWeb.ExternalFileCollectionController do
  use BlueJetWeb, :controller

  alias JaSerializer.Params
  alias BlueJet.FileStorage

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

    {:ok, %AccessResponse{ data: external_file_collections, meta: meta }} = FileStorage.list_external_file_collection(request)

    render(conn, "index.json-api", data: external_file_collections, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])
  end

  def create(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "data" => data = %{ "type" => "ExternalFileCollection" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads]
    }

    case FileStorage.create_external_file_collection(request) do
      {:ok, %AccessResponse{ data: efc }} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: efc, opts: [include: conn.query_params["include"]])
      {:error, %AccessResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))
    end
  end

  def show(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "id" => efc_id }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ external_file_collection_id: efc_id },
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    {:ok, %AccessResponse{ data: efc }} = FileStorage.get_external_file_collection(request)

    render(conn, "show.json-api", data: efc, opts: [include: conn.query_params["include"]])
  end

  def update(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "id" => efc_id, "data" => data = %{ "type" => "ExternalFileCollection" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ external_file_collection_id: efc_id },
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case FileStorage.update_external_file_collection(request) do
      {:ok, %AccessResponse{ data: efc }} ->
        render(conn, "show.json-api", data: efc, opts: [include: conn.query_params["include"]])
      {:error, %AccessResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))
    end
  end

  def delete(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "id" => efc_id }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ external_file_collection_id: efc_id }
    }

    FileStorage.delete_external_file_collection(request)

    send_resp(conn, :no_content, "")
  end

end
