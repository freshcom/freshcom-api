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

  @type t :: Ecto.Schema.t

  @system_fields [
    :encrypted_value,
    :reset_token,
    :reset_token_expires_at,
    :updated_at
  ]

  @required_fields [
    :value
  ]

  def writable_fields do
    [:value]
  end

  #
  # MARK: Validate
  #
  def validate(changeset) do
    changeset
    |> validate_required(:value)
    |> validate_length(:value, min: 8)
  end

  def changeset(password, :update, params) do
    password
    |> cast(params, writable_fields())
    |> Map.put(:action, :update)
    |> put_encrypted_value()
    |> validate()
  end

  def encrypt_value(value) do
    Comeonin.Bcrypt.hashpwsalt(value)
  end

  defp put_encrypted_value(changeset = %{ changes: %{ value: value } })  do
    put_change(changeset, :encrypted_value, encrypt_value(value))
  end
end
