defmodule BlueJet.Identity.AccountMembership do
  use BlueJet, :data

  alias BlueJet.Identity.{Account, User}

  schema "account_memberships" do
    field :role, :string
    field :is_owner, :boolean, default: false

    timestamps()

    belongs_to :account, Account
    belongs_to :user, User
  end

  @type t :: Ecto.Schema.t()

  @system_fields [
    :id,
    :account_id,
    :inserted_at,
    :updated_at
  ]

  @roles [
    "customer",
    "business_analyst",
    "support_specialist",
    "marketing_specialist",
    "goods_specialist",
    "developer",
    "administrator"
  ]

  def writable_fields do
    __MODULE__.__schema__(:fields) -- @system_fields
  end

  @spec changeset(__MODULE__.t(), atom, map) :: Changeset.t()
  def changeset(membership, :insert, params) do
    membership
    |> cast(params, castable_fields(:insert))
    |> Map.put(:action, :insert)
    |> validate()
  end

  def changeset(membership, :update, params) do
    membership
    |> cast(params, castable_fields(:update))
    |> Map.put(:action, :update)
    |> validate()
  end

  defp castable_fields(:insert), do: writable_fields()
  defp castable_fields(:update), do: writable_fields() -- [:user_id]

  @spec validate(Changeset.t()) :: Changeset.t()
  def validate(changeset = %{action: :insert}) do
    changeset
    |> validate_required([:user_id, :role])
    |> validate_inclusion(:role, @roles)
  end

  def validate(changeset = %{action: :update}) do
    changeset
    |> validate_required(:role)
    |> validate_inclusion(:role, @roles)
  end
end
