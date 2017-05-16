defmodule BlueJet.Registration do
  alias BlueJet.Repo
  alias BlueJet.User
  alias BlueJet.Account
  alias BlueJet.AccountMembership
  alias BlueJet.RefreshToken

  use BlueJet.Web, :model

  schema "users" do
    field :email, :string
    field :first_name, :string
    field :last_name, :string

    field :password, :string, virtual: true
    field :account_name, :string, virtual: true
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:email, :password, :first_name, :last_name, :account_name])
    |> validate_required([:email, :password, :first_name, :last_name, :account_name])
    |> validate_length(:password, min: 8)
    |> validate_format(:email, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
  end

  def sign_up(%Ecto.Changeset{ changes: params }) do
    Repo.transaction(fn ->
      with {:ok, account} <- Account.changeset(%Account{}, %{ name: Map.get(params, :account_name) }) |> Repo.insert,
           {:ok, user} <- User.changeset(%User{}, Map.put(params, :default_account_id, account.id)) |> Repo.insert,
           {:ok, _refresh_token} <- RefreshToken.changeset(%RefreshToken{}, %{ user_id: user.id, account_id: account.id }) |> Repo.insert,
           {:ok, _refresh_token} <- RefreshToken.changeset(%RefreshToken{}, %{ account_id: account.id }) |> Repo.insert,
           {:ok, _membership} <- AccountMembership.changeset(%AccountMembership{}, %{ role: "admin", account_id: account.id, user_id: user.id }) |> Repo.insert
      do
        user
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end
  def sign_up(params) do
    with changeset = %Ecto.Changeset{ valid?: true } <- changeset(%BlueJet.Registration{}, params)
    do
      sign_up(changeset)
    else
      changeset ->
        {:error, changeset}
    end
  end
end
