defmodule BlueJet.ExternalFileCollectionMembershipController do
  use BlueJet.Web, :controller

  alias BlueJet.ExternalFileCollectionMembership
  alias JaSerializer.Params

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn, _params) do
    external_file_collection_membership = Repo.all(ExternalFileCollectionMembership)
    render(conn, "index.json-api", data: external_file_collection_membership)
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

  def update(conn = %{ assigns: %{ locale: locale, vas: %{ account_id: account_id, user_id: _ } } }, %{"id" => id, "data" => data = %{"type" => "ExternalFileCollectionMembership"}}) do
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
