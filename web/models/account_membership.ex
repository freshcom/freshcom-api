defmodule BlueJet.AccountMembership do
  use BlueJet.Web, :model

  alias BlueJet.Account
  alias BlueJet.User

  schema "account_memberships" do
    field :role, :string

    timestamps()

    belongs_to :user, User
    belongs_to :account, Account
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct = %{ __meta__: %{ state: :built } }, params) do
    struct
    |> cast(params, [:role, :user_id, :account_id])
    |> validate_required([:role, :user_id, :account_id])
  end
  def changeset(struct = %{ __meta__: %{ state: :loaded } }, params) do
    struct
    |> cast(params, [:role])
    |> validate_required([:role])
  end
end
