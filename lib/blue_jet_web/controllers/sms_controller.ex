defmodule BlueJetWeb.SmsController do
  use BlueJetWeb, :controller

  alias JaSerializer.Params
  alias BlueJet.Notification

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn = %{ assigns: assigns }, params) do
    request = %ContextRequest{
      vas: assigns[:vas],
      search: params["search"],
      filter: assigns[:filter],
      pagination: %{ size: assigns[:page_size], number: assigns[:page_number] },
      preloads: assigns[:preloads]
    }

    case Notification.list_sms(request) do
      {:ok, %{ data: smses, meta: meta }} ->
        render(conn, "index.json-api", data: smses, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      other -> other
    end
  end

  def show(conn = %{ assigns: assigns }, %{ "id" => id }) do
    request = %ContextRequest{
      vas: assigns[:vas],
      params: %{ "id" => id },
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Notification.get_sms(request) do
      {:ok, %{ data: sms, meta: meta }} ->
        render(conn, "show.json-api", data: sms, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      other -> other
    end
  end
end
