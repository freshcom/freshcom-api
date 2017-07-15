defmodule BlueJet.ExternalFileCollectionController do
  use BlueJet.Web, :controller

  alias JaSerializer.Params
  alias BlueJet.FileStorage

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn = %{ assigns: assigns = %{ vas: %{ account_id: _, user_id: _ } } }, params) do
    request = %{
      vas: assigns[:vas],
      search_keyword: params["search"],
      filter: assigns[:filter],
      page_size: assigns[:page_size],
      page_number: assigns[:page_number],
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }
    %{ external_file_collections: efcs,
       total_count: total_count,
       result_count: result_count } = FileStorage.list_external_file_collections(request)

    meta = %{
      totalCount: total_count,
      resultCount: result_count
    }

    render(conn, "index.json-api", data: efcs, opts: [meta: meta, include: conn.query_params["include"]])
  end

  def create(conn = %{ assigns: assigns = %{ vas: %{ account_id: _, user_id: _ } } }, %{ "data" => data = %{ "type" => "ExternalFileCollection" } }) do
    request = %{
      vas: assigns[:vas],
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads]
    }

    case FileStorage.create_external_file_collection(request) do
      {:ok, efc} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: efc, opts: [include: conn.query_params["include"]])
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(changeset))
    end
  end

  def show(conn = %{ assigns: assigns = %{ vas: %{ account_id: _ } } }, %{ "id" => efc_id }) do
    request = %{
      vas: assigns[:vas],
      external_file_collection_id: efc_id,
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    efc = FileStorage.get_external_file_collection!(request)

    render(conn, "show.json-api", data: efc, opts: [include: conn.query_params["include"]])
  end

  def update(conn = %{ assigns: assigns = %{ vas: %{ account_id: _, user_id: _ } } }, %{ "id" => efc_id, "data" => data = %{ "type" => "ExternalFileCollection" } }) do
    request = %{
      vas: assigns[:vas],
      external_file_collection_id: efc_id,
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case FileStorage.update_external_file_collection(request) do
      {:ok, efc} ->
        render(conn, "show.json-api", data: efc, opts: [include: conn.query_params["include"]])
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(changeset))
    end
  end

  def delete(conn = %{ assigns: assigns = %{ vas: %{ account_id: _, user_id: _ } } }, %{ "id" => efc_id }) do
    request = %{
      vas: assigns[:vas],
      external_file_collection_id: efc_id
    }

    FileStorage.delete_external_file_collection!(request)

    send_resp(conn, :no_content, "")
  end

end
