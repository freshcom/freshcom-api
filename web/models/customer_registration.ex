defmodule BlueJet.CustomerRegistration do
  alias BlueJet.Repo
  alias BlueJet.Customer
  alias BlueJet.RefreshToken

  use BlueJet.Web, :model

  schema "users" do
    field :email, :string
    field :first_name, :string
    field :last_name, :string
    field :account_id, :string

    field :password, :string, virtual: true
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:email, :password, :first_name, :last_name, :account_id])
    |> validate_required([:email, :password, :first_name, :last_name, :account_id])
    |> validate_length(:password, min: 8)
    |> validate_format(:email, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
  end

  def sign_up(%Ecto.Changeset{ changes: params }) do
    Repo.transaction(fn ->
      with {:ok, customer} <- Customer.changeset(%Customer{}, params) |> Repo.insert,
           {:ok, _refresh_token} <- RefreshToken.changeset(%RefreshToken{}, %{ customer_id: customer.id, account_id: customer.account_id }) |> Repo.insert
      do
        customer
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end
  def sign_up(params) do
    with changeset = %Ecto.Changeset{ valid?: true } <- changeset(%BlueJet.CustomerRegistration{}, params)
    do
      sign_up(changeset)
    else
      changeset ->
        {:error, changeset}
    end
  end
end
