defmodule BlueJet.Identity.User do
  use BlueJet, :data

  alias Ecto.Changeset

  alias BlueJet.Identity.User
  alias BlueJet.Identity.Account
  alias BlueJet.Identity.RefreshToken
  alias BlueJet.Identity.AccountMembership

  schema "users" do
    field :email, :string
    field :encrypted_password, :string
    field :first_name, :string
    field :last_name, :string

    field :password, :string, virtual: true

    timestamps()

    belongs_to :default_account, Account
    belongs_to :account, Account
    has_many :refresh_tokens, RefreshToken
    has_many :account_memberships, AccountMembership
  end

  def system_fields do
    [
      :id,
      :encrypted_password,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    (User.__schema__(:fields) -- system_fields()) ++ [:password]
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:default_account_id]
  end

  def validate(changeset) do
    changeset
    |> validate_required([:email, :password, :first_name, :last_name, :default_account_id])
    |> validate_length(:password, min: 8)
    |> validate_format(:email, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
    |> foreign_key_constraint(:default_account_id)
    |> foreign_key_constraint(:account_id)
    |> unique_constraint(:email)
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, castable_fields(struct))
    |> validate()
    |> put_encrypted_password()
  end

  defp put_encrypted_password(changeset = %Changeset{ valid?: true, changes: %{ password: password } })  do
    put_change(changeset, :encrypted_password, Comeonin.Bcrypt.hashpwsalt(password))
  end
  defp put_encrypted_password(changeset), do: changeset


  defmodule Query do
    use BlueJet, :query

    def preloads(:default_account) do
      [default_account: Account.Query.default()]
    end
    def preloads({:default_account, default_account_preloads}) do
      [default_account: {Account.Query.default(), Account.Query.preloads(default_account_preloads)}]
    end
    def preloads(:refresh_tokens) do
      [refresh_tokens: RefreshToken.Query.default()]
    end
    def preloads(:account_memberships) do
      [account_memberships: AccountMembership.Query.default()]
    end
  end
end
