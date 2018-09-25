defmodule BlueJetWeb.ProductCollectionMembershipController do
  use BlueJetWeb, :controller

  alias BlueJet.Catalogue

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def index(%{assigns: assigns} = conn, params) do
    filter = Map.merge(assigns[:filter], %{collection_id: params["product_collection_id"]})

    conn
    |> assign(:filter, filter)
    |> default(:index, &Catalogue.list_product_collection_membership/1)
  end

  # def index(conn = %{ assigns: assigns }, params) do
  #   request = %ContextRequest{
  #     vas: assigns[:vas],
  #     params: %{ "collection_id" => params["product_collection_id"] },
  #     filter: assigns[:filter],
  #     pagination: %{ size: assigns[:page_size], number: assigns[:page_number] },
  #     preloads: assigns[:preloads],
  #     locale: assigns[:locale]
  #   }

  #   {:ok, %ContextResponse{ data: product_collection_memberships, meta: meta }} = Catalogue.list_product_collection_membership(request)

  #   render(conn, "index.json-api", data: product_collection_memberships, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])
  # end

  # def create(conn = %{ assigns: assigns }, %{ "product_collection_id" => pc_id, "data" => data = %{ "type" => "ProductCollectionMembership" } }) do
  #   request = %ContextRequest{
  #     vas: assigns[:vas],
  #     params: %{ "collection_id" => pc_id },
  #     fields: Params.to_attributes(data),
  #     preloads: assigns[:preloads]
  #   }

  #   case Catalogue.create_product_collection_membership(request) do
  #     {:ok, %{ data: pcm, meta: meta }} ->
  #       conn
  #       |> put_status(:created)
  #       |> render("show.json-api", data: pcm, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

  #     {:error, %{ errors: errors }} ->
  #       conn
  #       |> put_status(:unprocessable_entity)
  #       |> render(:errors, data: extract_errors(errors))

  #     other -> other
  #   end
  # end

  def create(conn, %{"data" => %{"type" => "ProductCollectionMembership"}}),
    do: default(conn, :create, &Catalogue.create_product_collection_membership/1)

  def show(conn, %{"id" => _}),
    do: default(conn, :show, &Catalogue.get_product_collection_membership/1)

  def update(conn, %{"id" => _, "data" => %{"type" => "ProductCollectionMembership"}}),
    do: default(conn, :update, &Catalogue.update_product_collection_membership/1)

  def delete(conn, %{"id" => _}),
    do: default(conn, :delete, &Catalogue.delete_product_collection_membership/1)

  # def delete(conn = %{ assigns: assigns }, %{ "id" => id }) do
  #   request = %ContextRequest{
  #     vas: assigns[:vas],
  #     params: %{ "id" => id }
  #   }

  #   case Catalogue.delete_product_collection_membership(request) do
  #     {:ok, _} -> send_resp(conn, :no_content, "")

  #     other -> other
  #   end
  # end

end
