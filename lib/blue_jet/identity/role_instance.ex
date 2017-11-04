defmodule BlueJet.Identity.RoleInstance do
  use BlueJet, :data
  use Trans, translates: [:custom_data], container: :translations

  alias BlueJet.Identity.Role
  alias BlueJet.Identity.RoleInstance
  alias BlueJet.Identity.AccountMembership

  @type t :: Ecto.Schema.t

  schema "role_instances" do
    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    timestamps()

    belongs_to :role, Role
    belongs_to :account, Account
    belongs_to :account_membership, AccountMembership
  end

  def system_fields do
    [
      :id,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    RoleInstance.__schema__(:fields) -- system_fields()
  end

  def translatable_fields do
    RoleInstance.__trans__(:fields)
  end

  def castable_fields(%RoleInstance{ __meta__: %{ state: :built }}) do
    writable_fields()
  end
  def castable_fields(payment = %RoleInstance{ __meta__: %{ state: :loaded }}) do
    fields = writable_fields() -- [:account_membership_id, :account_id]
  end

  def required_fields(_) do
    [:account_membership_id, :account_id, :role_id]
  end

  def validate(changeset) do
    changeset
    |> validate_required(required_fields(changeset))
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}, locale \\ "en") do
    struct
    |> cast(params, castable_fields(struct))
    |> validate()
    |> Translation.put_change(translatable_fields(), locale)
  end



  defmodule Query do
    use BlueJet, :query

    def preloads(:role) do
      [role: Role.Query.default()]
    end

    def default() do
      from(a in RoleInstance, order_by: [desc: :inserted_at])
    end
  end
end
