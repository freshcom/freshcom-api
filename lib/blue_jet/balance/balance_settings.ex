defmodule BlueJet.Balance.BalanceSettings do
  use BlueJet, :data

  alias Ecto.Changeset
  alias BlueJet.Balance.IdentityService

  schema "balance_settings" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :stripe_user_id, :string
    field :stripe_livemode, :boolean
    field :stripe_access_token, :string
    field :stripe_refresh_token, :string
    field :stripe_publishable_key, :string
    field :stripe_scope, :string

    field :country, :string, default: "CA"
    field :default_currency, :string, default: "CAD"

    field :stripe_variable_fee_percentage, :decimal, default: Decimal.new(2.90)
    field :stripe_fixed_fee_cents, :integer, default: 30
    field :freshcom_transaction_fee_percentage, :decimal, default: Decimal.new(1.59)

    field :stripe_auth_code, :string, virtual: true

    timestamps()
  end

  @type t :: Ecto.Schema.t

  @system_fields [
    :id,
    :account_id,
    :stripe_user_id,
    :stripe_livemode,
    :stripe_access_token,
    :stripe_refresh_token,
    :stripe_publishable_key,
    :stripe_scope,
    :stripe_variable_fee_percentage,
    :stripe_fixed_fee_cents,
    :freshcom_transaction_fee_percentage,
    :inserted_at,
    :updated_at
  ]

  def writable_fields do
    (__MODULE__.__schema__(:fields) -- @system_fields) ++ [:stripe_auth_code]
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, writable_fields())
  end

  def for_account(%{ id: account_id }) do
    Repo.get_by!(__MODULE__, account_id: account_id)
  end

  def get_account(settings) do
    settings.account || IdentityService.get_account(settings)
  end

  @doc """
  Process the given account.

  This function may change data in the database.

  Returns the processed account.

  The given `account` should be a account that is just created/updated using the `changeset`.
  """
  @spec process(__MODULE__.t, Changeset.t) :: {:ok, __MODULE__.t} | {:error. map}
  def process(balance_settings, %{ data: %{ stripe_auth_code: nil }, changes: %{ stripe_auth_code: stripe_auth_code }}) do
    account = get_account(balance_settings)

    with {:ok, data} <- create_stripe_access_token(stripe_auth_code, mode: account.mode) do
      changeset = change(balance_settings, %{
        stripe_user_id: data["stripe_user_id"],
        stripe_livemode: data["stripe_livemode"],
        stripe_access_token: data["access_token"],
        stripe_refresh_token: data["stripe_refresh_token"],
        stripe_publishable_key: data["stripe_publishable_key"],
        stripe_scope: data["scope"]
      })

      balance_settings = Repo.update!(changeset)
      {:ok, balance_settings}
    else
      {:error, errors} -> {:error, [stripe_auth_code: { errors["error_description"], [code: errors["error"], full_error_message: true] }]}
    end
  end
  def process(balance_settings, _), do: {:ok, balance_settings}

  @spec create_stripe_access_token(String.t, Map.t) :: {:ok, map} | {:error, map}
  defp create_stripe_access_token(stripe_auth_code, options) do
    key = if options[:mode] == "test" do
      System.get_env("STRIPE_TEST_SECRET_KEY")
    else
      System.get_env("STRIPE_LIVE_SECRET_KEY")
    end
    OauthClient.post("https://connect.stripe.com/oauth/token", %{ client_secret: key, code: stripe_auth_code, grant_type: "authorization_code" })
  end
end