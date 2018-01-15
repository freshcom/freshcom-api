defmodule BlueJet.Identity.AccountMembership do
  use BlueJet, :data

  alias BlueJet.Identity.Account
  alias BlueJet.Identity.User

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

  def writable_fields do
    __MODULE__.__schema__(:fields) -- @system_fields
  end

  defp castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields()
  end

  defp castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:user_id]
  end

  defp required_fields() do
    [:user_id, :role]
  end

  def validate(changeset) do
    changeset
    |> validate_required(required_fields())
    |> foreign_key_constraint(:user_id)
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params) do
    struct
    |> cast(params, castable_fields(struct))
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
