defmodule BlueJetWeb.FileCollectionMembershipController do
  use BlueJetWeb, :controller

  alias JaSerializer.Params
  alias BlueJet.FileStorage

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  # def index(conn = %{ assigns: assigns = %{ vas: %{ account_id: _ } } }, _) do
  #   request = %{
  #     vas: assigns[:vas],
  #     filter: assigns[:filter],
  #     page_size: assigns[:page_size],
  #     page_number: assigns[:page_number],
  #     preloads: assigns[:preloads],
  #     locale: assigns[:locale]
  #   }

  #   %{ file_collection_memberships: efcms,
  #      total_count: total_count,
  #      result_count: result_count } = FileStorage.list_file_collection_memberships(request)

  #   meta = %{
  #     totalCount: total_count,
  #     resultCount: result_count
  #   }

  #   render(conn, "index.json-api", data: efcms, opts: [meta: meta, include: conn.query_params["include"]])
  # end

  def create(conn = %{ assigns: assigns }, %{ "file_collection_id" => fc_id, "data" => data = %{ "type" => "FileCollectionMembership" } }) do
    request = %ContextRequest{
      vas: assigns[:vas],
      params: %{ "collection_id" => fc_id },
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads]
    }

    case FileStorage.create_file_collection_membership(request) do
      {:ok, %{ data: fcm, meta: meta }} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: fcm, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      {:error, %ContextResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))

      other -> other
    end
  end

  def update(conn = %{ assigns: assigns }, %{ "id" => fcm_id, "data" => data = %{ "type" => "FileCollectionMembership" } }) do
    request = %ContextRequest{
      vas: assigns[:vas],
      params: %{ "id" => fcm_id },
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case FileStorage.update_file_collection_membership(request) do
      {:ok, %{ data: fcm, meta: meta }} ->
        render(conn, "show.json-api", data: fcm, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      {:error, %ContextResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))

      other ->
        other
    end
  end

  def delete(conn = %{ assigns: assigns }, %{ "id" => fcm_id }) do
    request = %ContextRequest{
      vas: assigns[:vas],
      params: %{ "id" => fcm_id }
    }

    {:ok, _} = FileStorage.delete_file_collection_membership(request)

    send_resp(conn, :no_content, "")
  end
end
