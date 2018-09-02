defmodule BlueJet.Identity.Password do
  use BlueJet, :data

  alias BlueJet.Identity.Account

  schema "users" do
    field :encrypted_value, :string, source: :encrypted_password

    field :reset_token, :string, source: :password_reset_token
    field :reset_token_expires_at, :utc_datetime, source: :password_reset_token_expires_at
    field :updated_at, :utc_datetime, source: :password_updated_at

    field :value, :string, virtual: true

    belongs_to :account, Account
  end

  @type t :: Ecto.Schema.t()

  def writable_fields do
    [:value, :reset_token, :reset_token_expires_at]
  end

  @spec changeset(String.t(), atom, map) :: Changeset.t()
  def changeset(password, :update, params) do
    password
    |> cast(params, writable_fields())
    |> Map.put(:action, :update)
    |> put_encrypted_value()
    |> validate()
  end

  defp validate(changeset) do
    changeset
    |> validate_required(:value)
    |> validate_length(:value, min: 8)
  end

  defp encrypt_value(value) do
    Comeonin.Bcrypt.hashpwsalt(value)
  end

  defp put_encrypted_value(changeset = %{changes: %{value: value}}) do
    put_change(changeset, :encrypted_value, encrypt_value(value))
  end

  defp put_encrypted_value(changeset), do: changeset
end
