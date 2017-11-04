defmodule BlueJet.Billing.StripeAccount do
  # @type t :: Ecto.Schema.t

  # @doc """
  # Process the given account.

  # This function may change data in the database.

  # Returns the processed account.

  # The given `account` should be a account that is just created/updated using the `changeset`.
  # """
  # @spec process(Account.t, Changeset.t) :: {:ok, Account.t} | {:error. map}
  # def process(account = %Account{ stripe_code: stripe_code }, changeset) when not is_nil(stripe_code) do
  #   with {:ok, data} <- create_stripe_access_token(stripe_code) do
  #     changeset = Changeset.change(account, %{
  #       stripe_user_id: data["stripe_user_id"],
  #       stripe_livemode: data["stripe_livemode"],
  #       stripe_access_token: data["access_token"],
  #       stripe_refresh_token: data["stripe_refresh_token"],
  #       stripe_publishable_key: data["stripe_publishable_key"],
  #       stripe_scope: data["scope"]
  #     })

  #     account = Repo.update!(changeset)
  #     {:ok, account}
  #   else
  #     {:error, errors} -> {:error, [stripe_code: { errors["error_description"], [code: errors["error"], full_error_message: true] }]}
  #   end
  # end
  # def process(account, _), do: account

  # @spec create_stripe_access_token(string) :: {:ok, map} | {:error, map}
  # defp create_stripe_access_token(stripe_code) do
  #   key = System.get_env("STRIPE_SECRET_KEY")
  #   OauthClient.post("https://connect.stripe.com/oauth/token", %{ client_secret: key, code: stripe_code, grant_type: "authorization_code" })
  # end
end