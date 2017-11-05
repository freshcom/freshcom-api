defmodule BlueJet.Identity.AccountMembership do
  use BlueJet, :data

  alias BlueJet.Identity.AccountMembership
  alias BlueJet.Identity.Account
  alias BlueJet.Identity.User

  schema "account_memberships" do
    field :role, :string

    timestamps()

    belongs_to :account, Account
    belongs_to :user, User
  end

  def system_fields do
    [
      :id,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    AccountMembership.__schema__(:fields) -- system_fields()
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:user_id, :account_id]
  end

  def required_fields(_) do
    [:role, :user_id, :account_id]
  end

  def validate(changeset) do
    changeset
    |> validate_required(required_fields(changeset))
    |> foreign_key_constraint(:account_id)
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

    def default() do
      from(a in AccountMembership, order_by: [desc: :inserted_at])
    end
  end
end
