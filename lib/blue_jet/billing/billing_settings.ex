defmodule BlueJet.Billing.BillingSettings do
  use BlueJet, :data

  alias Ecto.Changeset

  alias BlueJet.Repo
  alias BlueJet.Identity
  alias BlueJet.AccessRequest

  alias BlueJet.Billing.BillingSettings

  @type t :: Ecto.Schema.t

  schema "billing_settings" do
    field :account_id, Ecto.UUID

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

    field :account, :map, virtual: true

    timestamps()
  end

  def system_fields do
    [
      :id,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    (BillingSettings.__schema__(:fields) -- system_fields()) ++ [:stripe_auth_code]
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:account_id]
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, castable_fields(struct))
  end

  def for_account(%{ mode: "test", live_account_id: account_id }) do
    Repo.get_by!(BillingSettings, account_id: account_id)
  end
  def for_account(%{ id: account_id, mode: "live" }) do
    Repo.get_by!(BillingSettings, account_id: account_id)
  end

  def account(%{ account_id: account_id, account: nil }) do
    case Identity.do_get_account(%AccessRequest{ vas: %{ account_id: account_id } }) do
      {:ok, %{ data: account }} -> account
      {:error, _} -> nil
    end
  end
  def account(%{ account: account }), do: account

  @doc """
  Process the given account.

  This function may change data in the database.

  Returns the processed account.

  The given `account` should be a account that is just created/updated using the `changeset`.
  """
  @spec process(BillingSettings.t, Changeset.t) :: {:ok, BillingSettings.t} | {:error. map}
  def process(billing_settings, %{ data: %{ stripe_auth_code: nil }, changes: %{ stripe_auth_code: stripe_auth_code }}) do
    account = account(%{ account_id: billing_settings.account_id, account: nil })

    with {:ok, data} <- create_stripe_access_token(stripe_auth_code, mode: account.mode) do
      changeset = Changeset.change(billing_settings, %{
        stripe_user_id: data["stripe_user_id"],
        stripe_livemode: data["stripe_livemode"],
        stripe_access_token: data["access_token"],
        stripe_refresh_token: data["stripe_refresh_token"],
        stripe_publishable_key: data["stripe_publishable_key"],
        stripe_scope: data["scope"]
      })

      billing_settings = Repo.update!(changeset)
      {:ok, billing_settings}
    else
      {:error, errors} -> {:error, [stripe_auth_code: { errors["error_description"], [code: errors["error"], full_error_message: true] }]}
    end
  end
  def process(billing_settings, _), do: {:ok, billing_settings}

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