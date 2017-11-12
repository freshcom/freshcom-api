defmodule BlueJet.Billing.StripeAccount do
  use BlueJet, :data

  alias Ecto.Changeset
  alias BlueJet.Billing.StripeAccount

  @type t :: Ecto.Schema.t

  schema "stripe_accounts" do
    field :account_id, Ecto.UUID

    field :stripe_user_id, :string
    field :stripe_livemode, :boolean
    field :stripe_access_token, :string
    field :stripe_refresh_token, :string
    field :stripe_publishable_key, :string
    field :stripe_scope, :string
    field :transaction_fee_percentage, :decimal, default: Decimal.new(4.49)

    field :auth_code, :string, virtual: true

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
    (StripeAccount.__schema__(:fields) -- system_fields()) ++ [:auth_code]
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

  @doc """
  Process the given account.

  This function may change data in the database.

  Returns the processed account.

  The given `account` should be a account that is just created/updated using the `changeset`.
  """
  @spec process(StripeAccount.t, Changeset.t) :: {:ok, StripeAccount.t} | {:error. map}
  def process(stripe_account, %{ data: %{ auth_code: nil }, changes: %{ auth_code: auth_code }}) do
    with {:ok, data} <- create_stripe_access_token(auth_code) do
      changeset = Changeset.change(stripe_account, %{
        stripe_user_id: data["stripe_user_id"],
        stripe_livemode: data["stripe_livemode"],
        stripe_access_token: data["access_token"],
        stripe_refresh_token: data["stripe_refresh_token"],
        stripe_publishable_key: data["stripe_publishable_key"],
        stripe_scope: data["scope"]
      })

      stripe_account = Repo.update!(changeset)
      {:ok, stripe_account}
    else
      {:error, errors} -> {:error, [auth_code: { errors["error_description"], [code: errors["error"], full_error_message: true] }]}
    end
  end
  def process(stripe_account, _), do: {:ok, stripe_account}

  @spec create_stripe_access_token(string) :: {:ok, map} | {:error, map}
  defp create_stripe_access_token(auth_code) do
    key = System.get_env("STRIPE_SECRET_KEY")
    OauthClient.post("https://connect.stripe.com/oauth/token", %{ client_secret: key, code: auth_code, grant_type: "authorization_code" })
  end
end