defmodule BlueJet.Balance.Settings do
  use BlueJet, :data

  alias __MODULE__.Proxy

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

  @spec changeset(__MODULE__, action, map) :: Changeset.t
  def changeset(struct, :update, params \\ %{}) do
    struct
    |> cast(params, writable_fields())
    |> put_stripe_data()
  end

  defp put_stripe_data(changeset = %{ changes: %{ stripe_auth_code: stripe_auth_code }}) do
    account = Proxy.get_account(changeset.data)

    with {:ok, stripe_data} <- Proxy.create_stripe_access_token(stripe_auth_code, mode: account.mode) do
      sync_from_stripe_data(changeset, stripe_data)
    else
      {:error, errors} ->
        add_error(changeset, :stripe_auth_code, errors["error_description"], code: errors["error"])
    end
  end

  defp put_stripe_data(changeset = %{ changes: %{ stripe_user_id: _ } }) do
    sync_from_stripe_data(changeset, %{})
  end

  defp put_stripe_data(changeset), do: changeset

  defp sync_from_stripe_data(changeset, stripe_data) do
    changeset
    |> put_change(:stripe_user_id, stripe_data["stripe_user_id"])
    |> put_change(:stripe_livemode, stripe_data["stripe_livemode"])
    |> put_change(:stripe_access_token, stripe_data["stripe_access_token"])
    |> put_change(:stripe_refresh_token, stripe_data["stripe_refresh_token"])
    |> put_change(:stripe_publishable_key, stripe_data["stripe_publishable_key"])
    |> put_change(:stripe_scope, stripe_data["stripe_scope"])
  end

  @spec for_account(String.t) :: __MODULE__.t
  def for_account(account_id) do
    Repo.get_by!(__MODULE__, account_id: account_id)
  end
end