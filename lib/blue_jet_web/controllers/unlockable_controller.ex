defmodule BlueJetWeb.UnlockableController do
  use BlueJetWeb, :controller

  alias JaSerializer.Params
  alias BlueJet.Goods

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

    {:ok, %AccessResponse{ data: unlockables, meta: meta }} = Goods.list_unlockable(request)

    render(conn, "index.json-api", data: unlockables, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])
  end

def create(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "data" => data = %{ "type" => "Unlockable" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads]
    }

    case Goods.create_unlockable(request) do
      {:ok, %AccessResponse{ data: unlockable }} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: unlockable, opts: [include: conn.query_params["include"]])
      {:error, %AccessResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))
    end
  end

  def show(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "id" => id }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ id: id },
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    {:ok, %AccessResponse{ data: unlockable }} = Goods.get_unlockable(request)

    render(conn, "show.json-api", data: unlockable, opts: [include: conn.query_params["include"]])
  end

  def update(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "id" => id, "data" => data = %{ "type" => "Unlockable" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ id: id },
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Goods.update_unlockable(request) do
      {:ok, %AccessResponse{ data: unlockable }} ->
        render(conn, "show.json-api", data: unlockable, opts: [include: conn.query_params["include"]])
      {:error, %AccessResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))
    end
  end

  def delete(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "id" => id }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ id: id }
    }

    Goods.delete_unlockable(request)

    send_resp(conn, :no_content, "")
  end
end
