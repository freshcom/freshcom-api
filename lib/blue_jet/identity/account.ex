defmodule BlueJet.Identity.Account do
  use BlueJet, :data

  alias BlueJet.Identity.Account

  schema "accounts" do
    field :name, :string
    field :stripe_user_id, :string
    field :stripe_access_token, :string
    field :stripe_refresh_token, :string
    field :stripe_publishable_key, :string
    field :stripe_livemode, :boolean
    field :stripe_scope, :string
    field :stripe_code, :string, virtual: true

    timestamps()
  end

  @type t :: Ecto.Schema.t

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :stripe_code])
  end

  @doc """
  Process the given account.

  This function may have side effect.

  Returns the processed account.

  The given `account` should be a account that is just created/updated using the `changeset`.
  """
  @spec process(Account.t, Changeset.t) :: {:ok, Account.t} | {:error. map}
  def process(account = %Account{ stripe_code: stripe_code }, changeset) when not is_nil(stripe_code) do
    with {:ok, access_token } <- create_stripe_access_token(stripe_code) do
      IO.inspect access_token
      {:ok, account}
    else
      other -> {:ok, account}
    end
  end
  def process(account, _), do: account

  @spec create_stripe_access_token(string) :: {:ok, map} | {:error, map}
  defp create_stripe_access_token(stripe_code) do
    key = System.get_env("STRIPE_SECRET_KEY")
    OauthHttpClient.post("https://connect.stripe.com/oauth/token", %{ client_secret: key, code: stripe_code, grant_type: "authorization_code" })
  end
end
