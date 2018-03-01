defmodule BlueJet.Identity.AccountMembership do
  use BlueJet, :data

  alias BlueJet.Identity.{Account, User}

  schema "account_memberships" do
    field :role, :string

    timestamps()

    belongs_to :account, Account
    belongs_to :user, User
  end

  @type t :: Ecto.Schema.t

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

  defp castable_fields(:insert), do: writable_fields()
  defp castable_fields(:update), do: writable_fields() -- [:user_id]

  #
  # MARK: Validate
  #
  def validate(changeset = %{ action: :insert }) do
    changeset
    |> validate_required([:user_id, :role])
    |> validate_inclusion(:role, @roles)
  end

  def validate(changeset = %{ action: :update }) do
    changeset
    |> validate_required(:role)
    |> validate_inclusion(:role, @roles)
  end

  #
  # MARK: Changeset
  #
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

  defmodule Query do
    use BlueJet, :query

    alias BlueJet.Identity.AccountMembership

    def default() do
      from(a in AccountMembership, order_by: [desc: :inserted_at])
    end

    def preloads(:account) do
      [account: Account.Query.default()]
    end
  end
end
