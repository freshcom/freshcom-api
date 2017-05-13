defmodule BlueJet.Registration do
  alias BlueJet.Repo
  alias BlueJet.User
  alias BlueJet.Account
  alias BlueJet.AccountMembership
  alias BlueJet.Jwt

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
      with {:ok, user} <- User.changeset(%User{}, params) |> Repo.insert,
           {:ok, account} <- Account.changeset(%Account{}, %{ name: Map.get(params, :account_name) }) |> Repo.insert,
           {:ok, _jwt} <- Jwt.changeset(%Jwt{}, %{ user_id: user.id, account_id: account.id, system_tag: "default", name: "Default" }) |> Repo.insert,
           {:ok, _jwt} <- Jwt.changeset(%Jwt{}, %{ account_id: account.id, system_tag: "public", name: "Public" }) |> Repo.insert,
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
