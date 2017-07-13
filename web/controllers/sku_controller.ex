defmodule BlueJet.SkuController do
  use BlueJet.Web, :controller

  alias JaSerializer.Params
  alias BlueJet.Sku
  alias BlueJet.Inventory

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn = %{ assigns: assigns = %{ vas: %{ account_id: account_id, user_id: _ } }, query_params: query_params }, params) do
    request = %{
      account_id: account_id,
      search_keyword: params["search"],
      filter: assigns[:filter],
      page_size: assigns[:page_size],
      page_number: assigns[:page_number],
      locale: assigns[:locale],
      include: assigns[:include]
    }
    %{ skus: skus, total_count: total_count, result_count: result_count } = Inventory.list_skus(request)

    meta = %{
      totalCount: total_count,
      resultCount: result_count
    }

    render(conn, "index.json-api", data: skus, opts: [meta: meta, include: query_params["include"], fields: query_params["fields"]])
  end

  def create(conn = %{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } }, %{ "data" => data = %{ "type" => "Sku" } }) do
    fields = Map.merge(Params.to_attributes(data), %{ "account_id" => account_id })
    changeset = Sku.changeset(%Sku{}, fields)

    case Repo.insert(changeset) do
      {:ok, sku} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: sku, opts: [include: conn.query_params["include"]])
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(changeset))
    end
  end

  def show(conn = %{ assigns: %{ locale: locale, vas: %{ account_id: account_id, user_id: _ } } }, %{ "id" => id }) do
    sku =
      Sku
      |> Repo.get_by!(account_id: account_id, id: id)
      |> Translation.translate(locale)

    render(conn, "show.json-api", data: sku, opts: [include: conn.query_params["include"]])
  end

  def update(conn = %{ assigns: %{ locale: locale, vas: %{ account_id: account_id, user_id: _ } } }, %{ "id" => id, "data" => data = %{ "type" => "Sku" } }) do
    sku = Repo.get_by!(Sku, account_id: account_id, id: id)
    changeset = Sku.changeset(sku, Params.to_attributes(data), locale)

    case Repo.update(changeset) do
      {:ok, sku} ->
        sku = Translation.translate(sku, locale)
        render(conn, "show.json-api", data: sku, opts: [include: conn.query_params["include"]])
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def delete(conn = %{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } }, %{ "id" => id }) do
    sku = Repo.get_by!(Sku, account_id: account_id, id: id)
    Repo.delete!(sku)

    send_resp(conn, :no_content, "")
  end
end
