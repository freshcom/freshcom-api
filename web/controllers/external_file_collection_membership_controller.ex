defmodule BlueJet.ExternalFileCollectionMembershipController do
  use BlueJet.Web, :controller

  alias BlueJet.ExternalFileCollectionMembership
  alias JaSerializer.Params

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn = %{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } }, _params) do
    query =
      ExternalFileCollectionMembership
      |> where([efcm], efcm.account_id == ^account_id)
      |> filter(collection_id: conn.query_params["filter"]["collectionId"], file_id: conn.query_params["fileId"])
    result_count = Repo.aggregate(query, :count, :id)

    total_query = ExternalFileCollectionMembership |> where([efcm], efcm.account_id == ^account_id)
    total_count = Repo.aggregate(total_query, :count, :id)

    query = paginate(query, size: conn.assigns[:page_size], number: conn.assigns[:page_number])

    memberships = Repo.all(query)
    meta = %{
      totalCount: total_count,
      resultCount: result_count
    }

    render(conn, "index.json-api", data: memberships, opts: [meta: meta, include: conn.query_params["include"], fields: conn.query_params["fields"]])
  end

  def create(%{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } } = conn, %{ "external_file_collection_id" => collection_id, "data" => data = %{ "type" => "ExternalFileCollectionMembership" } }) do
    fields = Map.merge(Params.to_attributes(data), %{ "account_id" => account_id, "collection_id" => collection_id })
    changeset = ExternalFileCollectionMembership.changeset(%ExternalFileCollectionMembership{}, fields)

    case Repo.insert(changeset) do
      {:ok, external_file_collection_membership} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: external_file_collection_membership, opts: [include: conn.query_params["include"]])
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def update(conn = %{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } }, %{"id" => id, "data" => data = %{"type" => "ExternalFileCollectionMembership"}}) do
    efcm = Repo.get_by!(ExternalFileCollectionMembership, account_id: account_id, id: id)
    changeset = ExternalFileCollectionMembership.changeset(efcm, Params.to_attributes(data))

    case Repo.update(changeset) do
      {:ok, external_file_collection_membership} ->
        render(conn, "show.json-api", data: external_file_collection_membership)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    external_file_collection_membership = Repo.get!(ExternalFileCollectionMembership, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(external_file_collection_membership)

    send_resp(conn, :no_content, "")
  end

end
