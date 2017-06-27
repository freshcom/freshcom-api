defmodule BlueJet.UnlockableController do
  use BlueJet.Web, :controller

  alias BlueJet.Unlockable
  alias JaSerializer.Params

  plug :scrub_params, "data" when action in [:create, :update]

  def index(%{ assigns: %{ locale: locale, vas: %{ account_id: account_id, user_id: _ } } } = conn, params) do
    query =
      Unlockable
      |> search([:name, :id], params["search"], locale)
      |> where([s], s.account_id == ^account_id)
    result_count = Repo.aggregate(query, :count, :id)

    total_query = Unlockable |> where([s], s.account_id == ^account_id)
    total_count = Repo.aggregate(total_query, :count, :id)

    query = paginate(query, size: conn.assigns[:page_size], number: conn.assigns[:page_number])

    unlockables =
      Repo.all(query)
      |> Translation.translate_collection(locale)
    meta = %{
      totalCount: total_count,
      resultCount: result_count
    }

    render(conn, "index.json-api", data: unlockables, opts: [meta: meta, include: conn.query_params["include"], fields: conn.query_params["fields"]])
  end

  def create(%{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } } = conn, %{"data" => data = %{"type" => "Unlockable", "attributes" => _unlockable_params}}) do
    fields = Map.merge(Params.to_attributes(data), %{ "account_id" => account_id })
    changeset = Unlockable.changeset(%Unlockable{}, fields)

    case Repo.insert(changeset) do
      {:ok, unlockable} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: unlockable, opts: [include: conn.query_params["include"]])
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(changeset))
    end
  end

  def show(%{ assigns: %{ locale: locale, vas: %{ account_id: account_id, user_id: _ } } } = conn, %{"id" => id}) do
    unlockable =
      Unlockable
      |> Repo.get_by!(account_id: account_id, id: id)
      |> Translation.translate(locale)
    render(conn, "show.json-api", data: unlockable, opts: [include: conn.query_params["include"]])
  end

  def update(%{ assigns: %{ locale: locale, vas: %{ account_id: account_id, user_id: _ } } } = conn, %{"id" => id, "data" => data = %{"type" => "Unlockable", "attributes" => _unlockable_params}}) do
    unlockable = Repo.get_by!(Unlockable, account_id: account_id, id: id)
    changeset = Unlockable.changeset(unlockable, Params.to_attributes(data), locale)

    case Repo.update(changeset) do
      {:ok, unlockable} ->
        unlockable = Translation.translate(unlockable, locale)
        render(conn, "show.json-api", data: unlockable, opts: [include: conn.query_params["include"]])
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def delete(%{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } } = conn, %{"id" => id}) do
    sku = Repo.get_by!(Unlockable, account_id: account_id, id: id)
    Repo.delete!(sku)

    send_resp(conn, :no_content, "")
  end

end
