defmodule BlueJet.Balance.Settings.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Balance.Settings
  alias BlueJet.Balance.{IdentityService, OauthClient}

  @doc """
  Sync the apporiate settings to the associated `Account`.

  Currently this function only changes the `is_ready_for_live_transaction`
  attribuets of the `Account`.
  """
  @spec sync_to_account(Settings.t()) :: {:ok, map} | {:error, map}
  def sync_to_account(settings) do
    account = get_account(settings)
    sync_to_account(settings, account)
  end

  defp sync_to_account(_, account = %{mode: "test"}), do: {:ok, account}

  defp sync_to_account(settings, account) do
    if settings.stripe_livemode do
      IdentityService.update_account(account, %{is_ready_for_live_transaction: true})
    else
      IdentityService.update_account(account, %{is_ready_for_live_transaction: false})
    end
  end

  @spec create_stripe_access_token(String.t(), map) :: {:ok, map} | {:error, map}
  def create_stripe_access_token(stripe_auth_code, options) do
    key =
      if options[:mode] == "test" do
        System.get_env("STRIPE_TEST_SECRET_KEY")
      else
        System.get_env("STRIPE_LIVE_SECRET_KEY")
      end

    OauthClient.post("https://connect.stripe.com/oauth/token", %{
      client_secret: key,
      code: stripe_auth_code,
      grant_type: "authorization_code"
    })
  end
end
