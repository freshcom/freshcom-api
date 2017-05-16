defmodule BlueJet.User do
  use BlueJet.Web, :model

  schema "users" do
    field :email, :string
    field :encrypted_password, :string
    field :first_name, :string
    field :last_name, :string

    field :password, :string, virtual: true

    timestamps()

    belongs_to :default_account, Account
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params) do
    struct
    |> cast(params, [:email, :password, :first_name, :last_name, :default_account_id])
    |> validate_required([:email, :password, :first_name, :last_name, :default_account_id])
    |> validate_length(:password, min: 8)
    |> validate_format(:email, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
    |> unique_constraint(:email)
    |> put_encrypted_password
  end

  defp put_encrypted_password(changeset = %Ecto.Changeset{ valid?: true, changes: %{ password: password } })  do
    put_change(changeset, :encrypted_password, Comeonin.Bcrypt.hashpwsalt(password))
  end
  defp put_encrypted_password(changeset), do: changeset
end
