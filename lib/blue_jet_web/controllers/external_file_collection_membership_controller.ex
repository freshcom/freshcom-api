defmodule BlueJetWeb.ExternalFileCollectionMembershipController do
  use BlueJetWeb, :controller

  # alias JaSerializer.Params
  # alias BlueJet.FileStorage

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

  #   %{ external_file_collection_memberships: efcms,
  #      total_count: total_count,
  #      result_count: result_count } = FileStorage.list_external_file_collection_memberships(request)

  #   meta = %{
  #     totalCount: total_count,
  #     resultCount: result_count
  #   }

  #   render(conn, "index.json-api", data: efcms, opts: [meta: meta, include: conn.query_params["include"]])
  # end

  # def create(conn = %{ assigns: assigns = %{ vas: %{ account_id: _, user_id: _ } } }, %{ "external_file_collection_id" => efc_id, "data" => data = %{ "type" => "ExternalFileCollectionMembership" } }) do
  #   fields = Map.merge(Params.to_attributes(data), %{ "collection_id" => efc_id })
  #   request = %{
  #     vas: assigns[:vas],
  #     fields: fields,
  #     preloads: assigns[:preloads]
  #   }

  #   case FileStorage.create_external_file_collection_membership(request) do
  #     {:ok, efcm} ->
  #       conn
  #       |> put_status(:created)
  #       |> render("show.json-api", data: efcm, opts: [include: conn.query_params["include"]])
  #     {:error, changeset} ->
  #       conn
  #       |> put_status(:unprocessable_entity)
  #       |> render(:errors, data: extract_errors(changeset))
  #   end
  # end

  # def update(conn = %{ assigns: assigns = %{ vas: %{ account_id: _, user_id: _ } } }, %{ "id" => efcm_id, "data" => data = %{ "type" => "ExternalFileCollectionMembership" } }) do
  #   request = %{
  #     vas: assigns[:vas],
  #     external_file_collection_membership_id: efcm_id,
  #     fields: Params.to_attributes(data),
  #     preloads: assigns[:preloads],
  #     locale: assigns[:locale]
  #   }

  #   case FileStorage.update_external_file_collection_membership(request) do
  #     {:ok, efcm} ->
  #       render(conn, "show.json-api", data: efcm, opts: [include: conn.query_params["include"]])
  #     {:error, changeset} ->
  #       conn
  #       |> put_status(:unprocessable_entity)
  #       |> render(:errors, data: changeset)
  #   end
  # end

  # def delete(conn = %{ assigns: assigns = %{ vas: %{ account_id: _, user_id: _ } } }, %{ "id" => efcm_id }) do
  #   request = %{
  #     vas: assigns[:vas],
  #     external_file_collection_membership_id: efcm_id
  #   }

  #   FileStorage.delete_external_file_collection_membership!(request)

  #   send_resp(conn, :no_content, "")
  # end
end
