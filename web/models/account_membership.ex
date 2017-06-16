defmodule BlueJet.AccountMembership do
  use BlueJet.Web, :model

  schema "account_memberships" do
    field :role, :string

    timestamps()

    belongs_to :account, BlueJet.Account
    belongs_to :user, BlueJet.User
  end

  def castable_fields(state) do
    all = [:role, :user_id, :account_id]

    case state do
      :built -> all
      :loaded -> all -- [:user_id, :account_id]
    end
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct = %{ __meta__: %{ state: state } }, params) do
    struct
    |> cast(params, castable_fields(state))
    |> validate_required([:role, :user_id, :account_id])
  end
end