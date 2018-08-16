defmodule BlueJetWeb.AccountMembershipController do
  use BlueJetWeb, :controller

  alias JaSerializer.Params
  alias BlueJet.Identity

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn = %{ assigns: assigns }, params) do
    filter =
      assigns[:filter]
      |> underscore_value([:role])

    request = %AccessRequest{
      vas: assigns[:vas],
      params: Map.take(params, ["target"]),
      search: params["search"],
      filter: filter,
      pagination: %{ size: assigns[:page_size], number: assigns[:page_number] },
      preloads: [:user, :account],
      locale: assigns[:locale]
    }

    case Identity.list_account_membership(request) do
      {:ok, %AccessResponse{ data: memberships, meta: meta }} ->
        render(conn, "index.json-api", data: memberships, opts: [meta: camelize_map(meta)])

      other -> other
    end
  end

  def update(conn = %{ assigns: assigns }, %{ "id" => id, "data" => data = %{ "type" => "AccountMembership" } }) do
    fields =
      Params.to_attributes(data)
      |> underscore_value(["role"])

    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ "id" => id },
      fields: fields,
      preloads: [:user, :account],
      locale: assigns[:locale]
    }

    case Identity.update_account_membership(request) do
      {:ok, %AccessResponse{ data: membership, meta: meta }} ->
        render(conn, "show.json-api", data: membership, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      {:error, %AccessResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))

      other -> other
    end
  end

end
