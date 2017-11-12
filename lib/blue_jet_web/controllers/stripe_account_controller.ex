defmodule BlueJetWeb.StripeAccountController do
  use BlueJetWeb, :controller

  alias BlueJet.Billing
  alias JaSerializer.Params

  plug :scrub_params, "data" when action in [:create, :update]

  def create(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "data" => data = %{ "type" => "StripeAccount" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads]
    }

    case Billing.create_stripe_account(request) do
      {:ok, %AccessResponse{ data: stripe_account }} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: stripe_account, opts: [include: conn.query_params["include"]])
      {:error, %AccessResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))
    end
  end

  def show(conn = %{ assigns: assigns = %{ vas: vas } }, _) do
    request = %AccessRequest{
      vas: vas
    }

    case Identity.get_account(request) do
      {:ok, %{ data: account }} ->
        render(conn, "show.json-api", data: account, opts: [include: conn.query_params["include"]])
    end
  end

  def update(conn = %{ assigns: assigns = %{ vas: %{ account_id: account_id, user_id: _ } } }, %{"data" => data = %{"type" => "Account", "attributes" => _account_params}}) do
    request = %{
      vas: assigns[:vas],
      account_id: account_id,
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Identity.update_account(request) do
      {:ok, order} ->
        render(conn, "show.json-api", data: order, opts: [include: conn.query_params["include"]])
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(changeset))
    end
  end

  def delete(conn, %{"id" => id}) do
    account = Repo.get!(Account, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(account)

    send_resp(conn, :no_content, "")
  end

end
